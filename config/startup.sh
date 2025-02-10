#!/usr/bin/env bash

set -xe

# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1

# Make forwarding persistent.
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# Configure ip_conntrack
# hashsize = nf_conntrack_max / 4
modprobe ip_conntrack hashsize=262144
echo "262144" >/sys/module/nf_conntrack/parameters/hashsize

# Increase conntrack table
sysctl -w net.netfilter.nf_conntrack_max=1048576
echo net.netfilter.nf_conntrack_max=1048576 >>/etc/sysctl.conf

interface=$(ip ro show default | awk '{print $5}')
iptables -t nat -A POSTROUTING -o "$interface" -j MASQUERADE

apt update

apt install -y conntrack

# Install nginx for instance http health check
apt install -y nginx

ENABLE_SQUID="${squid_enabled}"

if [[ "$ENABLE_SQUID" == "true" ]]; then
  apt install -y squid3

  cat - >/etc/squid/squid.conf <<'EOM'
${file("${squid_config == "" ? "${format("%s/config/squid.conf", module_path)}" : squid_config}")}
EOM

  systemctl reload squid
fi

# Install debug utils
ENABLE_DEBUG_UTILS="${debug_utils_enabled}"

if [[ "$ENABLE_DEBUG_UTILS" == "true" ]]; then
  apt install -y dnsutils traceroute
fi

ENABLE_OPS_AGENT="${ops_agent_enabled}"
if [[ "$ENABLE_OPS_AGENT" == "true" ]]; then
  curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  bash add-google-cloud-ops-agent-repo.sh --also-install
fi

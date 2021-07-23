#!/bin/bash -xe

# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1

# Make forwarding persistent.
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# Configure ip_conntrack
# hashsize = nf_conntrack_max / 4
modprobe ip_conntrack hashsize=131072
echo "131072" > /sys/module/nf_conntrack/parameters/hashsize

# Increase conntrack table
sysctl -w net.netfilter.nf_conntrack_max=524288
echo net.netfilter.nf_conntrack_max=524288 >> /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

apt-get update

apt-get install -y conntrack

# Install nginx for instance http health check
apt-get install -y nginx

ENABLE_SQUID="${squid_enabled}"

if [[ "$ENABLE_SQUID" == "true" ]]; then
  apt-get install -y squid3

  cat - > /etc/squid/squid.conf <<'EOM'
${file("${squid_config == "" ? "${format("%s/config/squid.conf", module_path)}" : squid_config}")}
EOM

  systemctl reload squid
fi

# Install debug utils
ENABLE_DEBUG_UTILS="${debug_utils_enabled}"

if [[ "$ENABLE_DEBUG_UTILS" == "true" ]]; then
  apt-get install -y dnsutils traceroute
fi

ENABLE_STACKDRIVER_AGENT="${stackdriver_monitoring_enabled}"
ENABLE_STACKDRIVER_LOGGING_AGENT="${stackdriver_logging_enabled}"

if [[ "$ENABLE_STACKDRIVER_AGENT" == "true" ]]; then
  curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh
  bash install-monitoring-agent.sh
fi

if [[ "$ENABLE_STACKDRIVER_LOGGING_AGENT" == "true" ]]; then
  curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
  bash install-logging-agent.sh
fi

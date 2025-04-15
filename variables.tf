/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "module_enabled" {
  description = "To disable this module, set this to false"
  default     = true
}

variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable "network" {
  description = "The network to deploy to"
  default     = "default"
}

variable "network_project" {
  description = "Name of the project for the network. Useful for shared VPC. Default is var.project."
  default     = ""
}

variable "subnetwork" {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable "region" {
  description = "The region to create the nat gateway instance in."
}

variable "zone" {
  description = "Override the zone used in the `region_params` map for the region."
  default     = ""
}

variable "name" {
  description = "Prefix added to the resource names, for example 'prod-'. By default, resources will be named in the form of '<name>nat-gateway-<zone>'"
  default     = ""
}

variable "ip_address_name" {
  description = "Name of an existing reserved external address to use."
  default     = ""
}

variable "tags" {
  description = "Additional compute instance network tags to apply route to."
  type        = list(string)
  default     = []
}

variable "use_target_tags" {
  description = "Weather or not to use tags to target the NAT Gateway route or use the entire network"
  type        = bool
  default     = true
}

variable "nat_ig_tags" {
  description = "Tags for all the NAT Gateway instances"
  type        = list(string)
  default     = []
}

variable "route_priority" {
  description = "The priority for the Compute Engine Route"
  default     = 800
}

variable "machine_type" {
  description = "The machine type for the NAT gateway instances"
  default     = "n1-standard-2"
}

variable "min_cpu_platform" {
  description = "Specifies a minimum CPU platform. Applicable values are the friendly names of CPU platforms, such as Intel Haswell or Intel Skylake. See the complete list: https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform"
  default     = null
}

variable "compute_image" {
  description = "Image used for NAT compute VMs."
  default     = "debian-11"
}

variable "compute_family" {
  description = "Image family used for NAT compute VMs."
  default     = "debian-cloud"
}

variable "ip" {
  description = "Override the internal IP. If not provided, an internal IP will automatically be assigned."
  default     = ""
}

variable "squid_enabled" {
  description = "Enable squid3 proxy on port 3128."
  default     = "false"
}

variable "debug_utils_enabled" {
  description = "Install dnsutils and traceroute for debugging purposes"
  default     = "false"
}

variable "ops_agent_enabled" {
  description = "Enable ops agent"
  default     = "true"
}

variable "squid_config" {
  description = "The squid config file to use. If not specifed the module file config/squid.conf will be used."
  default     = ""
}

variable "metadata" {
  description = "Metadata to be attached to the NAT gateway instance"
  type        = map(any)
  default     = {}
}

variable "ssh_fw_rule" {
  description = "Whether or not the SSH Firewall Rule should be created"
  default     = true
}

variable "ssh_source_ranges" {
  description = "Network ranges to allow SSH from"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "labels" {
  description = "Labels added to instances."
  type        = map(any)
  default     = {}
}

variable "service_account_email" {
  description = "The email of the service account for the instance template."
  default     = "default"
}

variable "autohealing_enabled" {
  description = "Enable instance autohealing using http health check"
  default     = false
}

variable "region_params" {
  description = "Map of default zones and IPs for each region. Can be overridden using the `zone` and `ip` variables."
  type        = map(any)

  default = {
    asia-east1 = {
      zone = "asia-east1-b"
    }

    asia-east2 = {
      zone = "asia-east2-b"
    }

    asia-northeast1 = {
      zone = "asia-northeast1-b"
    }

    asia-south1 = {
      zone = "asia-south1-b"
    }

    asia-southeast1 = {
      zone = "asia-southeast1-b"
    }

    australia-southeast1 = {
      zone = "australia-southeast1-b"
    }

    europe-north1 = {
      zone = "europe-north1-b"
    }

    europe-west1 = {
      zone = "europe-west1-b"
    }

    europe-west2 = {
      zone = "europe-west2-b"
    }

    europe-west3 = {
      zone = "europe-west3-b"
    }

    europe-west4 = {
      zone = "europe-west4-b"
    }

    northamerica-northeast1 = {
      zone = "northamerica-northeast1-b"
    }

    southamerica-east1 = {
      zone = "southamerica-east1-b"
    }

    us-central1 = {
      zone = "us-central1-f"
    }

    us-east1 = {
      zone = "us-east1-b"
    }

    us-east4 = {
      zone = "us-east4-b"
    }

    us-west1 = {
      zone = "us-west1-b"
    }

    us-west2 = {
      zone = "us-west2-b"
    }
  }
}

variable "dest_ranges" {
  description = "The destination IPv4 address range that this route applies to"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_exporter_enabled" {
  description = "Enable node exporter"
  default     = "true"
}

variable "node_exporter_version" {
  description = "Node exporter version"
  default     = "1.9.1"
}

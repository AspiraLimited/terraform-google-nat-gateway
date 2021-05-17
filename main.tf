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

data "template_file" "nat-startup-script" {
  template = file(format("%s/config/startup.sh", path.module))

  vars = {
    squid_enabled                  = var.squid_enabled
    squid_config                   = var.squid_config
    module_path                    = path.module
    debug_utils_enabled            = var.debug_utils_enabled
    stackdriver_monitoring_enabled = var.stackdriver_monitoring_enabled
    stackdriver_logging_enabled    = var.stackdriver_logging_enabled
  }
}

data "google_compute_network" "network" {
  name    = var.network
  project = var.network_project == "" ? var.project : var.network_project
}

data "google_compute_address" "default" {
  count   = var.ip_address_name == "" ? 0 : 1
  name    = var.ip_address_name
  project = var.network_project == "" ? var.project : var.network_project
  region  = var.region
}

data "google_compute_region_instance_group" "nat-group" {
  project   = var.project
  region    = var.region
  self_link = module.nat-gateway.instance_group
  # blocks defers reading of the data source until after all changes to the dependencies have been applied.
  depends_on = [module.nat-gateway]
}

data "google_compute_instance" "nat-server" {
  self_link = data.google_compute_region_instance_group.nat-group.instances[0].instance
}

locals {
  zone          = var.zone == "" ? lookup(var.region_params[var.region], "zone") : var.zone
  name          = "${var.name}nat-gateway-${local.zone}"
  instance_tags = ["inst-${local.zonal_tag}", "inst-${local.regional_tag}"]
  zonal_tag     = "${var.name}nat-${local.zone}"
  regional_tag  = "${var.name}nat-${var.region}"
}

module "instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "6.4.0"
  project_id         = var.project
  region             = var.region
  subnetwork         = var.subnetwork
  subnetwork_project = var.project
  can_ip_forward     = true
  tags               = compact(concat(local.instance_tags, var.nat_ig_tags))
  labels             = var.instance_labels
  service_account = {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
  machine_type         = var.machine_type
  name_prefix          = local.name
  source_image_family  = var.compute_image
  source_image_project = var.compute_family
  startup_script       = data.template_file.nat-startup-script.rendered
  metadata             = var.metadata
  access_config = [{
    nat_ip       = try(google_compute_address.default.0.address, data.google_compute_address.default.0.address)
    network_tier = "PREMIUM"
  }]
}

module "nat-gateway" {
  source             = "terraform-google-modules/vm/google//modules/mig"
  version            = "6.4.0"
  project_id         = var.project
  region             = var.region
  network            = var.network
  subnetwork         = var.subnetwork
  subnetwork_project = var.project
  hostname           = local.name
  instance_template  = module.instance_template.self_link
  target_size        = 1
  wait_for_instances = "true"
  update_policy = [{
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 0
    max_surge_percent            = null
    max_unavailable_fixed        = 3
    max_unavailable_percent      = null
    min_ready_sec                = 30
    instance_redistribution_type = "PROACTIVE"
  }]
  health_check = {
    type                = var.autohealing_enabled ? "http" : ""
    initial_delay_sec   = 30
    check_interval_sec  = 30
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 80
    request             = ""
    request_path        = "/"
    host                = ""
  }
  distribution_policy_zones = [local.zone]
}

resource "google_compute_route" "nat-gateway" {
  for_each = toset(var.dest_ranges)
  name = format(
    "%v-route-%v",
    local.zonal_tag,
    replace(split("/", each.key)[0], ".", "-")
  )
  project                = var.project
  dest_range             = each.value
  network                = data.google_compute_network.network.self_link
  next_hop_instance      = data.google_compute_instance.nat-server.self_link
  next_hop_instance_zone = local.zone
  tags                   = var.use_target_tags ? compact(concat(tolist([local.regional_tag, local.zonal_tag]), var.tags)) : []
  priority               = var.route_priority
}

resource "google_compute_firewall" "nat-gateway" {
  count   = var.module_enabled ? 1 : 0
  name    = local.zonal_tag
  network = var.network
  project = var.project

  allow {
    protocol = "all"
  }

  source_tags = var.use_target_tags ? compact(concat(tolist([local.regional_tag, local.zonal_tag]), var.tags)) : []
  target_tags = compact(concat(local.instance_tags, var.tags))
}

resource "google_compute_address" "default" {
  count   = var.module_enabled && var.ip_address_name == "" ? 1 : 0
  name    = local.zonal_tag
  project = var.project
  region  = var.region
}

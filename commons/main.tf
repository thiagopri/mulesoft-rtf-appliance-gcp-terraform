# For DEV environment define :
# Terraform version , required GCP provider
terraform {
  required_version = ">= 1.0.7"

  #For BACKEND configuration details, please refer to backend.tf under each environment folder (i.e DEV/backend.tf)

  required_providers {
    google = {
      version     = "~> 3.5.0"
      source = "hashicorp/google"
    }
  }

}
# Use google provider
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.gcp_auth_file)
}

###########################
# Validation steps
locals {
  create_vpc = length(var.vpc_name) > 0
  create_subnet = length(var.subnet_name) > 0  
  vpc_link = local.create_vpc ? google_compute_network.default[0].self_link : var.shared_vpc_name
  subnet_link = local.create_subnet ? google_compute_subnetwork.default[0].self_link : var.shared_subnet_name

  validate_rtf_params = length(var.rtf_activation_data) == 0 && length(var.rtf_name) == 0
  validate_rtf_params_msg = "You MUST define either the RTF_NAME or the RTF_ACTIVATION_DATA."
  validate_rtf_params_chk = regex(
      "^${local.validate_rtf_params_msg}$",
      ( !local.validate_rtf_params
        ? local.validate_rtf_params_msg
        : "" ) )  
}


###########################
# VM Instances for RTF Cluster
module "rtf_cluster" {
  source = "../modules/compute/instance"

  #loop
  for_each = merge(var.rtf_cluster.controllers, var.rtf_cluster.workers)

  # Inputs
  prefix = var.prefix
  postfix = var.postfix
  boot_image = var.boot_image
  ssh_keys = var.ssh_keys
  name = "${var.prefix}${each.key}${var.postfix}"
  machine_type = each.value["machine_type"]
  network_vpc = local.vpc_link
  subnet = local.subnet_link
  ip = each.value["ip"]
  tags = each.value["tags"]
  zone = each.value["zone"]
  type = each.key
  disks = each.value["disks"]
  gcp_user = var.gcp_user
  rtf_name = var.rtf_name
  rtf_version = var.rtf_version
  rtf_appliance_version = var.rtf_appliance_version
  rtf_activation_data = var.rtf_activation_data
  rtf_mule_license = var.rtf_mule_license
  pod_network_cidr = var.pod_network_cidr
  service_cidr = var.service_cidr
  leader_ip = each.value.leader_ip
  install_role = each.value.install_role
  node_role = each.value.node_role
}

###########################
# GCP HTTPs External LB when configured
module "rtf_https_loadbalancer" {
  source = "../modules/network/global-https-lb"
  count  = (var.create_https_lb == true) ? 1 : 0

  name        = "${var.prefix}${var.default_lb_name}${var.postfix}"
  default_lb_external_ip = var.default_lb_external_ip
  managed_cert_name = var.managed_cert_name
  controllers = var.rtf_cluster.controllers
  vms = module.rtf_cluster

  depends_on = [module.rtf_cluster]
}

###########################
# GCP HTTP External LB when configured
module "rtf_http_loadbalancer" {
  source = "../modules/network/global-http-lb"
  count  = (var.create_http_lb == true) ? 1 : 0

  name        = "${var.prefix}${var.default_lb_name}${var.postfix}"
  default_lb_external_ip = var.default_lb_external_ip
  controllers = var.rtf_cluster.controllers
  vms = module.rtf_cluster

  depends_on = [module.rtf_cluster]
}
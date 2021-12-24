# GCP authentication file
variable "gcp_auth_file" {
  description = "Credentials file (JSON KEY) to be used by the Terraform scripts"
  type        = string
}

# Project
variable "project_id" {
  description = "GCP Project ID to be used by the scripts"
  type        = string
}

# Project Region
variable "region" {
  description = "GCP Project region"
  type        = string
  default     = "northamerica-northeast2"
}

# Shared VPC
variable "shared_vpc_name" {
  description = "Self link of the VPC to be assigned to the created VM"
  type        = string
}

# Shared Subnet
variable "shared_subnet_name" {
  description = "Self link of the subnet to be assigned to the created VM"
  type        = string
}

# VPC
variable "vpc_name" {
  description = "Name for the VPC to be created and assigned to the created VM"
  type        = string
}

# Subnet
variable "subnet_name" {
  description = "Name for the Subnet to be created and assigned to the created VM"
  type        = string
}

# prefix 
variable "prefix" {
  description = "Prefix to be added on the resources' name"
  type        = string
  default     = ""
}

# postfix 
variable "postfix" {
  description = "Postfix to be added on the resources' name"
  type        = string
  default     = ""
}

variable "boot_image" {
  description = "Boot image details to be used by VMs"
  type = object({
    source  = string
    size    = string
    type    = string
  })
}

variable "gcp_user" {
  description = "GCP user to be created on the VM"
  type        = string
}

variable "rtf_activation_data" {
  description = "RTF Activation Token to be used by the RTF script on the startup script"
  type        = string
  default     = ""
}

# rtf_name 
variable "rtf_name" {
  description = "RTF Cluster Name to be used by the RTF script on the startup script. It is ignored if Token is present."
  type        = string
  default     = ""
}

# rtf_version 
variable "rtf_version" {
  description = "RTF Agent version to be installed. If not specified it will use the latest available version"
  type        = string
  default     = ""
}

# rtf_appliance_version 
variable "rtf_appliance_version" {
  description = "RTF Appliance version to be installed. If not specified it will use the latest available version"
  type        = string
  default     = ""
}

variable "rtf_mule_license" {
  description = "Base64 MuleSoft license"
  type        = string
}

variable "pod_network_cidr" {
  description = "CIDR for the K8S POD network. It must not colid with existing CIDR within the same VPC"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR for the K8S Services network. It must not colid with existing CIDR within the same VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "ssh_keys" {
  description = "Public SSH keys to be included on the created VM. The key should belong to the user who will login on the VM using the private key later on."
  type        = string
}

variable rtf_cluster {
  description = "Definition of the RTF Cluster to be created"
  type        = object({
    controllers = map(object({
      ip  = string
      machine_type  = string
      tags  = list(string)
      install_role  = string
      node_role  = string
      leader_ip  = string
      zone  = string
      disks  = map(object({
          type = string
          size = string
      }))
    })),
    workers = map(object({
      ip  = string
      machine_type  = string
      tags  = list(string)
      install_role  = string
      node_role  = string
      leader_ip  = string
      zone  = string
      disks  = map(object({
          type = string
          size = string
      }))
    })),    
  })
}

variable create_https_lb {
  description = "Wheter the HTTPS LB should be created as part of the execution or not. If it is true, all the controllers will be added to this LB"
  type        = bool
  default     = false  
}

variable create_http_lb {
  description = "Wheter the HTTP LB should be created as part of the execution or not. If it is true, all the controllers will be added to this LB"
  type        = bool
  default     = false  
}

variable default_lb_name {
  description = "Name of the LB to be created"
  type        = string
}

variable managed_cert_name {
  description = "Name of the SSL certificate to be used on this LB (must be added in advanced)"
  type        = string
}

variable default_lb_external_ip {
  description = "External IP to be assigned on this LB (must be reserved in advanced)"
  type        = string
}

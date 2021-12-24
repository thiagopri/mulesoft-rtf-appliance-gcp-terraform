# name 
variable "name" {
  description = "Name of the VM to be created"
  type        = string
}

# machine_type 
variable "machine_type" {
  description = "GCP VM type (i.e custom-2-8192)"
  type        = string
}

# network_vpc 
variable "network_vpc" {
  description = "Self link of the VPC to be assigned to the created VM"
  type        = string
}

# ip 
variable "ip" {
  description = "Internal IP address to be assigned to the created VM"
  type        = string
}

# type 
variable "type" {
  description = "Type to be used on the disk name to ensure it is unique (i.e controller-1, worker-1)"
  type        = string
}

# subnet 
variable "subnet" {
  description = "Self link of the subnet to be assigned to the created VM"
  type        = string
}

# tags 
variable "tags" {
  description = "Network tags to be assigned to the created VM"
  type        = list(string)
}

# vm_general_info 
variable "boot_image" {
  description = "Boot image details to be used by VMs"
  type = object({
    source  = string
    size    = string
    type    = string
  })
}

# ssh_keys 
variable "ssh_keys" {
  description = "Public SSH keys to be included on the created VM. The key should belong to the user who will login on the VM using the private key later on."
  type        = string
  default     = ""
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

# zone 
variable "zone" {
  description = "Zone where the VM will be created"
  type        = string
}

# disks 
variable "disks" {
  description = "Map of the disks to be attached to the created VM"
  type        = map(object({
    type  = string
    size  = string
  }))
}

# gcp_user 
variable "gcp_user" {
  description = "GCP user to be created on the VM"
  type        = string
}

# rtf_activation_data 
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

# rtf_mule_license 
variable "rtf_mule_license" {
  description = "Base64 MuleSoft license"
  type        = string
}

# pod_network_cidr 
variable "pod_network_cidr" {
  description = "CIDR for the K8S POD network. It must not colid with existing CIDR within the same VPC"
  type        = string
}

# service_cidr 
variable "service_cidr" {
  description = "CIDR for the K8S Services network. It must not colid with existing CIDR within the same VPC"
  type        = string
}

# leader_ip 
variable "leader_ip" {
  description = "IP of the leader VM of the RTF Cluster"
  type        = string
  default     = ""
}

# install_role 
variable "install_role" {
  description = "Role of the VM during the RTF cluster installation (leader or joiner)"
  type        = string
}

# node_role 
variable "node_role" {
  description = "Role of the VM in the RTF cluster (controller_node or worker_node)"
  type        = string
}

# managed_certs 
variable "managed_cert_name" {
  description = "Name of the SSL certificate to be used on this LB (must be added in advanced)"
  type        = string
}

# name 
variable "name" {
  description = "Name of the LB to be created"
  type        = string
}

# default_lb_external_ip 
variable "default_lb_external_ip" {
  description = "External IP to be assigned on this LB (must be reserved in advanced)"
  type        = string
}

# controllers 
variable "controllers" {
  description = "Controllers VMs to be included on this LB"
  type        = map(object({
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
  }))
}

# VMS 
variable "vms" {
  description = "VMs used on the RTF cluster (Module output)"
}
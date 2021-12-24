output "vm" {
  value       = google_compute_instance.rtf_vm
  description = "Instance created"
}

output "disk" {
  value       = google_compute_disk.rtf_vm_disk
  description = "Disk created"
}

output "zone" {
  value       = var.zone
  description = "VM Zone"
}

output "node_role" {
  value       = var.node_role
  description = "VM node_role"
}

output "network_vpc" {
  value       = var.network_vpc
  description = "VM network_vpc"
}

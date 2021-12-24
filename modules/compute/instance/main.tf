
data "template_file" "rtf_startup_script" {
  template = file("${path.module}/startup-script.sh")
  vars = {
    rtf_name = "${var.rtf_name}"
    rtf_version = "${var.rtf_version}"
    rtf_appliance_version = "${var.rtf_appliance_version}"
    rtf_activation_data = "${var.rtf_activation_data}"
    rtf_mule_license = "${var.rtf_mule_license}"
    pod_network_cidr = "${var.pod_network_cidr}"
    service_cidr = "${var.service_cidr}"
    gcp_user = "${var.gcp_user}" 
    leader_ip = "${var.leader_ip}" 
    private_ip = "${var.ip}" 
    install_role = "${var.install_role}" 
    node_role = "${var.node_role}"
  }
}

resource "google_compute_disk" "rtf_vm_disk" {
  for_each = var.disks
  name    = "${var.prefix}rtf-disk-${var.type}-disk-${each.key}${var.postfix}"
  type    = each.value.type
  zone    = var.zone
  size    = each.value.size
}

resource "google_compute_instance" "rtf_vm" {

  dynamic "attached_disk" {
    for_each = var.disks
    content {
      source      = google_compute_disk.rtf_vm_disk[attached_disk.key].self_link
      device_name      = google_compute_disk.rtf_vm_disk[attached_disk.key].name
    }
  }

  
  boot_disk {
    auto_delete = "true"
    device_name = "rtf-bootdisk-vm-${var.name}"

    initialize_params {
      image = var.boot_image.source
      size  = var.boot_image.size
      type  = var.boot_image.type
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = "false"
  deletion_protection = "false"
  enable_display      = "false"
  machine_type        = var.machine_type
  name                = "${var.name}"

  # Network interface
  network_interface {
    network    = var.network_vpc
    network_ip = var.ip
    subnetwork = var.subnet

    #Enable external IP
    access_config {}
  }
  # network tags
  tags = var.tags

  metadata = {
    ssh-keys = var.ssh_keys
  }  

  zone = var.zone

  metadata_startup_script = data.template_file.rtf_startup_script.rendered

}
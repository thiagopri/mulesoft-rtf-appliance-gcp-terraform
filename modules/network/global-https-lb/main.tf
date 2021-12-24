#Create HTTPS Proxy
resource "google_compute_target_https_proxy" "default_https" {
  name    = "default-https-proxy"
  url_map = "${google_compute_url_map.default_https.self_link}"
  ssl_certificates = [var.managed_cert_name]
}

#Create Front End HTTPS
resource "google_compute_global_forwarding_rule" "default_https" {
  name       = "default-https-lb-frontend-service"
  ip_address = var.default_lb_external_ip
  port_range = "443"
  load_balancing_scheme = "EXTERNAL"
  target     = "${google_compute_target_https_proxy.default_https.self_link}"
}

#Create Default Mapping
resource "google_compute_url_map" "default_https" {
  name        = "https-${var.name}"
  default_service = "${google_compute_backend_service.default_https.self_link}" 
}

#Create Backend Services
resource "google_compute_backend_service" "default_https" {
  name                     = "default-https-lb-backend-service"
  protocol                 = "HTTPS"
  port_name                = "https"
  load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  session_affinity         = "NONE"
  health_checks            = [google_compute_health_check.default_https.id]

  dynamic "backend" {
    for_each = google_compute_instance_group.default_https
    content {
      group           = google_compute_instance_group.default_https[backend.key].self_link
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0      
    }
  }

}

#Create New Certificate
# resource "google_compute_ssl_certificate" "default" {
#   name        = "rtf-qa-cert"
#   private_key = file("../certs/")
#   certificate = file("../certs/")
# }

#Create Health Check
resource "google_compute_health_check" "default_https" {
  name = "default-https-lb-health-check"

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 5
  unhealthy_threshold = 5

  ssl_health_check {
    port = "443"
  }
}

#Create Instance Group
resource "google_compute_instance_group" "default_https" {
  for_each = local.vms_by_zone
  name     = "default-https-lb-ig-${each.key}"
  zone     = each.key
  network  = each.value[0].network_vpc
  named_port {
    name = "https"
    port = 443
  }
  instances = each.value.*.vm.self_link
}

locals {
  vms_by_zone = {
    for key, value in var.controllers : value.zone => var.vms[key]...
  }  
}
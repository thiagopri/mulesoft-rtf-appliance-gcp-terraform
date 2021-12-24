#Create HTTP Proxy
resource "google_compute_target_http_proxy" "default_http" {
  name    = "default-http-proxy"
  url_map = "${google_compute_url_map.default_http.self_link}"
}

#Create Front End HTTP
resource "google_compute_global_forwarding_rule" "default_http" {
  name       = "default-http-lb-frontend-service"
  ip_address = var.default_lb_external_ip
  port_range = "80"
  load_balancing_scheme = "EXTERNAL"
  target     = "${google_compute_target_http_proxy.default_http.self_link}"
}

#Create Default Mapping
resource "google_compute_url_map" "default_http" {
  name        = "http-${var.name}"
  default_service = "${google_compute_backend_service.default_http.self_link}" 
}

#Create Backend Services
resource "google_compute_backend_service" "default_http" {
  name                     = "default-http-lb-backend-service"
  protocol                 = "HTTP"
  port_name                = "http"
  load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  session_affinity         = "NONE"
  health_checks            = [google_compute_health_check.default_http.id]

  dynamic "backend" {
    for_each = google_compute_instance_group.default_http
    content {
      group           = google_compute_instance_group.default_http[backend.key].self_link
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0      
    }
  }

}

#Create Health Check
resource "google_compute_health_check" "default_http" {
  name = "default-http-lb-health-check"

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 5
  unhealthy_threshold = 5

  tcp_health_check {
    port = "80"
  }
}

#Create Instance Group
resource "google_compute_instance_group" "default_http" {
  for_each = local.vms_by_zone
  name     = "default-http-lb-ig-${each.key}"
  zone     = each.key
  network  = each.value[0].network_vpc
  named_port {
    name = "http"
    port = 80
  }
  instances = each.value.*.vm.self_link
}

locals {
  vms_by_zone = {
    for key, value in var.controllers : value.zone => var.vms[key]...
  }  
}
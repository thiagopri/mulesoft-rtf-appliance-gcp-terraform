
###########################
# VPC to be used
resource "google_compute_network" "default" {
  count                   = local.create_vpc ? 1 : 0
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

###########################
# Subnet to be used
resource "google_compute_subnetwork" "default" {
  count                    = local.create_vpc && local.create_subnet ? 1 : 0
  name                     = var.subnet_name
  ip_cidr_range            = "10.188.0.0/20"
  network                  = google_compute_network.default[0].self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  count   = local.create_vpc ? 1 : 0
  name    = "internet-router"
  region  = var.region
  network = local.vpc_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "default" {
  count                              = local.create_vpc ? 1 : 0
  name                               = "internet-router-nat"
  router                             = google_compute_router.default[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "rtf-allow-ingress" {
  count          = local.create_vpc ? 1 : 0
  allow {
    ports    = ["22", "80", "443", "32009"]
    protocol = "tcp"
  }

  direction      = "INGRESS"
  disabled       = "false"
  enable_logging = "false"
  name           = "rtf-allow-ingress-from-internet${var.postfix}"
  network        = local.vpc_link
  priority       = "1000"
  source_ranges  = ["0.0.0.0/0"]
  target_tags    = ["rtf-controller"]
}

resource "google_compute_firewall" "rtf-allow-internal" {
  count          = local.create_vpc ? 1 : 0
  allow {
    protocol = "all"
  }

  direction      = "INGRESS"
  disabled       = "false"
  enable_logging = "false"
  name           = "rtf-allow-internal${var.postfix}"
  network        = local.vpc_link
  priority       = "1000"
  source_ranges  = ["10.188.0.0/20"]
  target_tags    = ["rtf-controller", "rtf-worker"]
}

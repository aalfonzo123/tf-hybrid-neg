data "google_compute_network" "vpc-1" {
  project = "meijer-gcp-core-842352947916e"
  name    = "vpc-1"
}

variable "proxy_cidr" {
  default = "10.123.0.0/24"
}

data "google_compute_subnetwork" "ilb-subnetwork" {
  name   = "subnet-1"
  region = "us-east4"
}

resource "google_compute_address" "ilb_address" {
  name         = "ilb-address"
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.ilb-subnetwork.id
  region       = data.google_compute_subnetwork.ilb-subnetwork.region
}

resource "google_compute_region_health_check" "backend-ilb-health-check" {
  name                = "backend-ilb-health-check"
  region              = data.google_compute_subnetwork.ilb-subnetwork.region
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 5 # 25 seconds

  tcp_health_check {
    port = "80"
  }
}


resource "google_compute_region_backend_service" "backend" {
  name                  = "backend"
  region                = data.google_compute_subnetwork.ilb-subnetwork.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTP"
  backend {
    group = google_compute_network_endpoint_group.hybrid-neg.id
    #group           = google_compute_network_endpoint_group.alf-vm-neg.id
    capacity_scaler = 1.0
    balancing_mode  = "RATE"
    max_rate        = 100
  }
  health_checks = [google_compute_region_health_check.backend-ilb-health-check.id]
}

resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "l7-ilb-proxy-subnet"
  ip_cidr_range = var.proxy_cidr
  region        = data.google_compute_subnetwork.ilb-subnetwork.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = data.google_compute_network.vpc-1.id
}

resource "google_compute_region_url_map" "default" {
  name            = "l7-ilb-regional-url-map"
  region          = "us-east4"
  default_service = google_compute_region_backend_service.backend.id
}

resource "google_compute_region_target_http_proxy" "default" {
  name    = "l7-ilb-target-http-proxy"
  region  = "us-east4"
  url_map = google_compute_region_url_map.default.id
}


resource "google_compute_forwarding_rule" "forwarding-rule-port" {
  depends_on  = [google_compute_subnetwork.proxy_subnet]
  name        = "forwarding-rule-port"
  ip_protocol = "TCP"
  #ports                 = ["80"]
  port_range            = "80"
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_address            = google_compute_address.ilb_address.id
  target                = google_compute_region_target_http_proxy.default.id
  region                = data.google_compute_subnetwork.ilb-subnetwork.region
  network               = data.google_compute_network.vpc-1.id
  subnetwork            = data.google_compute_subnetwork.ilb-subnetwork.id
}


# fw for monitoring
resource "google_compute_firewall" "fw_iap" {
  project       = "alf-monitoring-project"
  name          = "l7-ilb-fw-allow-iap-hc"
  direction     = "INGRESS"
  network       = data.google_compute_network.vpc-monitoring-1.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "fw_ilb_to_backends" {
  project       = "alf-monitoring-project"
  name          = "l7-ilb-fw-allow-ilb-to-backends"
  direction     = "INGRESS"
  network       = data.google_compute_network.vpc-monitoring-1.id
  source_ranges = [var.proxy_cidr]
  #target_tags   = ["http-server"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}

# fw for vpc-1
resource "google_compute_firewall" "fw-iap-local" {
  name          = "fw-iap-local"
  direction     = "INGRESS"
  network       = data.google_compute_network.vpc-1.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "fw-ilb-to-backends-local" {
  name          = "fw-ilb-to-backends-local"
  direction     = "INGRESS"
  network       = data.google_compute_network.vpc-1.id
  source_ranges = [var.proxy_cidr]
  #target_tags   = ["http-server"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}
resource "google_compute_network_endpoint_group" "hybrid-neg" {
  name                  = "hybrid-neg"
  network               = data.google_compute_network.vpc-1.id
  default_port          = "80"
  zone                  = "us-east4-a"
  network_endpoint_type = "NON_GCP_PRIVATE_IP_PORT"
}

resource "google_compute_network_endpoint" "alf-endpoint" {
  network_endpoint_group = google_compute_network_endpoint_group.hybrid-neg.name

  port       = google_compute_network_endpoint_group.hybrid-neg.default_port
  ip_address = google_compute_instance.server-vm.network_interface.0.network_ip
  zone       = google_compute_network_endpoint_group.hybrid-neg.zone
}



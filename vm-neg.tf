resource "google_compute_network_endpoint_group" "alf-vm-neg" {
  name                  = "alf-vm-neg"
  network               = data.google_compute_network.vpc-1.id
  subnetwork            = data.google_compute_subnetwork.ilb-subnetwork.id
  default_port          = "80"
  zone                  = "us-east4-a"
  network_endpoint_type = "GCE_VM_IP_PORT"
}

resource "google_compute_network_endpoint" "alf-vm-endpoint" {
  network_endpoint_group = google_compute_network_endpoint_group.alf-vm-neg.name

  instance   = google_compute_instance.local-server-vm.name
  port       = google_compute_network_endpoint_group.alf-vm-neg.default_port
  ip_address = google_compute_instance.local-server-vm.network_interface.0.network_ip
  zone       = "us-east4-a"
}



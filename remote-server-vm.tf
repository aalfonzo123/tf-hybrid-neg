data "google_compute_network" "vpc-monitoring-1" {
  project = "alf-monitoring-project"
  name    = "vpc-monitoring-1"
}

data "google_compute_subnetwork" "subnet-monitoring-us-west4" {
  project = "alf-monitoring-project"
  region  = "us-west4"
  name    = "subnet-monitoring-us-west4"
}

resource "google_service_account" "backend-sa" {
  project      = "alf-monitoring-project"
  account_id   = "backend-sa"
  display_name = "Service Account for backend VMs"
}

resource "google_compute_instance" "server-vm" {
  project                   = "alf-monitoring-project"
  name                      = "server-vm"
  machine_type              = "e2-medium"
  zone                      = "us-west4-a"
  allow_stopping_for_update = true
  #metadata_startup_script   = "sudo socat TCP-LISTEN:900,fork FD:1&"

  metadata = {
    startup-script = <<-EOF
 #! /bin/bash
 apt update
 apt -y install apache2
 echo "dummy server remote" > /var/www/html/index.html
  EOF
  }

  boot_disk {
    initialize_params {
      size  = "30"
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet-monitoring-us-west4.id
  }

  scheduling {
    provisioning_model = "SPOT"
    # provisioning_model = "STANDARD"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  service_account {
    email  = google_service_account.backend-sa.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}


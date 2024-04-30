data "google_compute_subnetwork" "subnet-1" {
  name   = "subnet-1"
  region = "us-east4"
}

resource "google_service_account" "client-sa" {
  account_id = "client-sa"
}

resource "google_compute_instance" "client-vm" {
  name                      = "client-vm"
  machine_type              = "e2-medium"
  zone                      = "us-east4-a"
  allow_stopping_for_update = true

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
    subnetwork = data.google_compute_subnetwork.subnet-1.id
  }

  scheduling {
    provisioning_model = "SPOT"
    # provisioning_model = "STANDARD"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  service_account {
    email  = google_service_account.client-sa.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}


resource "google_service_account" "local-sa" {
  account_id = "local-sa"
}

resource "google_compute_instance" "local-server-vm" {
  name                      = "local-server-vm"
  machine_type              = "e2-medium"
  zone                      = "us-east4-a"
  allow_stopping_for_update = true
  #metadata_startup_script   = "sudo socat TCP-LISTEN:900,fork FD:1&"

  metadata = {
    startup-script = <<-EOF
 #! /bin/bash
 apt update
 apt -y install apache2
 echo "dummy server" > /var/www/html/index.html
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
    subnetwork = data.google_compute_subnetwork.ilb-subnetwork.id
  }

  scheduling {
    provisioning_model = "SPOT"
    # provisioning_model = "STANDARD"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  service_account {
    email  = google_service_account.local-sa.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = [metadata["ssh-keys"]]
  }
}


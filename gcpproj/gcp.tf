provider "google"{
    credentials = "${file("terraform.json")}"
    project = "deploy-315515"
    region= "us-east1"
    zone =  "us-east1-c"
}

resource "tls_private_key" "kk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
#resource "google_project_service" "api" { 
#    for_each = toset([
#    "cloudresourcemanager.googleapis.com",
#    "compute.googleapis.com"
#    ])
#    disable_on_destroy = false
#    serviсe            = each.value
#}

resource "google_compute_firewall" "web"{
    name = "webnet"
    network = "default"
    source_ranges = ["0.0.0.0/0"]
    allow{
        protocol = "tcp"
        ports = ["22", "80" , "443"]
    }
}
resource "google_compute_address" "static" {
  name = "vm-public-address"
  project = "deploy-315515"
  region = "us-east1"
  depends_on = [ google_compute_firewall.web]
}
resource "google_compute_instance" "web"{
    name = "web"
    machine_type = "e2-micro"
    tags = ["webprod"]
    metadata = {
      ssh-keys = "ubuntu:${tls_private_key.kk.public_key_openssh}"
    }
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }
    network_interface{
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address 
     } 
    }
    provisioner "local-exec" {
    command = "echo '${tls_private_key.kk.private_key_pem}' > ./myKey.pem; chmod 600 ./myKey.pem"
    }
    provisioner "remote-exec" {
      inline = ["echo asd"]

    connection {
      host = google_compute_address.static.address
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.kk.private_key_pem}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${google_compute_address.static.address},' --private-key ./myKey.pem create.yml"
  }

   depends_on = [google_compute_firewall.web] 
}

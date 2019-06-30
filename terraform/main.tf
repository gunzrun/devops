provider "google" {
    version = "~> 2.5"
    project = "${var.project}"
    region  = "${var.region}"
}
resource "google_compute_instance" "app" {
    metadata = {
        ssh-keys = "den:${file(var.public_key_path)}"
    }
    name = "reddit-app"
    machine_type = "g1-small"
    zone = "europe-west1-b"
    tags = ["reddit-app"]
    
    # определение загрузочного диска
    boot_disk {
        initialize_params {
            image = "${var.disk_image}"
        }
    }
    
    # определение сетевого интерфейса
    network_interface {
        # сеть, к которой присоединить данный интерфейс
        network = "default"
        # использовать ephemeral IP для доступа из Интернет
        access_config {}
    }
    
    connection {
        host = "${google_compute_instance.app.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "den"
        agent = false
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "file" {
        source = "files/puma.service"
        destination = "/tmp/puma.service"
    }
    
    provisioner "remote-exec" {
        script = "files/deploy.sh"
    }
}

resource "google_compute_firewall" "firewall_puma" {
    name    = "allow-puma-default"
    # Название сети, в которой действует правило
    network = "default"
    # Какой доступ разрешить
    allow {
        protocol = "tcp"
        ports    = ["9292"]
    }
    # Каким адресам разрешаем доступ
    source_ranges = ["0.0.0.0/0"]
    # Правило применимо для инстансов с тегом ...
    target_tags = ["reddit-app"]
}

resource "google_compute_firewall" "firewall_ssh" {
    name    = "default-allow-ssh"
    # Название сети, в которой действует правило
    network = "default"
    # Какой доступ разрешить
    allow { 
        protocol = "tcp"
        ports    = ["22"]
    }
    # Каким адресам разрешаем доступ
    source_ranges = ["0.0.0.0/0"]
}

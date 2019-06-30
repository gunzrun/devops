provider "google" {
    version = "~> 2.5"
    project = "ace-falcon-237616"
    region  = "us-east1-b"
}
resource "google_compute_instance" "app" {
    metadata = {
        ssh-keys = "den:${file("~/.ssh/id_rsa.pub")}"
    }
    name = "reddit-app"
    machine_type = "g1-small"
    zone = "europe-west1-b"
    tags = ["reddit-app"]

    # определение загрузочного диска
    boot_disk {
        initialize_params {
            image = "reddit-base"
        }
    }
    
    # определение сетевого интерфейса
    network_interface {
        # сеть, к которой присоединить данный интерфейс
        network = "default"
        # использовать ephemeral IP для доступа из Интернет
        access_config {}
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

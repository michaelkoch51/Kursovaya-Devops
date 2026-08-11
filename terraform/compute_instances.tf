data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# 1. Бастион-хост (Публичный, только для SSH)
resource "yandex_compute_instance" "bastion" {
  name = "bastion-host"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 2. Веб-сервер 1 (Приватный, в зоне A)
resource "yandex_compute_instance" "web1" {
  name = "web-server-1"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 3. Веб-сервер 2 (Приватный, в зоне B)
resource "yandex_compute_instance" "web2" {
  name = "web-server-2"
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 4. Prometheus (Приватный, в зоне A)
resource "yandex_compute_instance" "prometheus" {
  name        = "monitoring-prometheus"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 5. Grafana (Публичная, в зоне A)
resource "yandex_compute_instance" "grafana" {
  name        = "monitoring-grafana"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Вывод публичного IP Grafana
output "grafana_public_ip" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

# 6. Elasticsearch (Приватный, в зоне A)
resource "yandex_compute_instance" "elasticsearch" {
  name        = "logging-elasticsearch"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 7. Kibana (Публичная, в зоне A)
resource "yandex_compute_instance" "kibana" {
  name        = "logging-kibana"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      type     = "network-hdd"
      size     = 20
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.ru-central1-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Вывод публичного IP Kibana
output "kibana_public_ip" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}


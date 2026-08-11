resource "yandex_vpc_network" "main" {
  name        = "main-network"
  description = "Main VPC network for devops course"
}

# 1. СОЗДАЕМ NAT-ШЛЮЗ
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# 2. СОЗДАЕМ ТАБЛИЦУ МАРШРУТИЗАЦИИ ДЛЯ ВЫХОДА В ИНТЕРНЕТ
resource "yandex_vpc_route_table" "private_route_table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# 3. ПОДСЕТЬ В ЗОНЕ А (Связываем с таблицей маршрутизации)
resource "yandex_vpc_subnet" "ru-central1-a" {
  name           = "subnet-ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
  zone           = "ru-central1-a"
  route_table_id = yandex_vpc_route_table.private_route_table.id # Добавили эту строку
}

# 4. ПОДСЕТЬ В ЗОНЕ Б
resource "yandex_vpc_subnet" "ru-central1-b" {
  name           = "subnet-ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone           = "ru-central1-b"
  route_table_id = yandex_vpc_route_table.private_route_table.id
}


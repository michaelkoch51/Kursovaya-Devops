# 1. Target Group (Целевая группа)
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group"

  target {
    # ИСПРАВЛЕНИЕ: Динамическая ссылка вместо "e9buf..."
    subnet_id  = yandex_vpc_subnet.ru-central1-a.id
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.ru-central1-b.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

# 2. Backend Group (Группа бэкендов + Настройка Healthcheck)
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group"

  http_backend {
    name             = "web-http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]

    healthcheck {
      timeout             = "1s"
      interval            = "3s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# 3. HTTP Router (Маршрутизатор запросов)
resource "yandex_alb_http_router" "web_router" {
  name = "web-http-router"
}

resource "yandex_alb_virtual_host" "web_vh" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "root-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout          = "60s"
      }
    }
  }
}

# 4. Application Load Balancer
resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-app-balancer"
  network_id         = yandex_vpc_network.main.id
  
  # ИСПРАВЛЕНИЕ: Динамическая ссылка на группу безопасности вместо "enp4..."
  security_group_ids = [yandex_vpc_security_group.web.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      # ИСПРАВЛЕНИЕ: Динамическая ссылка вместо "e9buf..."
      subnet_id = yandex_vpc_subnet.ru-central1-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.ru-central1-b.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {
          # Автоматически выделяет публичный IP-адрес
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}

# Автоматический вывод публичного IP балансировщика
output "balancer_public_ip" {
  value = yandex_alb_load_balancer.web_alb.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}


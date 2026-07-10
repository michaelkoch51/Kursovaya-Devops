# Kursovaya-Devops
# DevOps-практика: развёртывание Nginx в изолированной облачной подсети

**Статус:** ✅ Выполнено. Сервисы подтверждены на двух узлах.  
**Дата проверки:** 2026-07-09  
**ОС:** Ubuntu 22.04 (Jammy)  
**Версия Nginx:** 1.18.0 (Ubuntu)

---

## Цель работы

Развертывание веб‑сервера Nginx на двух серверах в приватной подсети облачной платформы, проверка доступности сервиса и анализ ограничений сетевого доступа к публичным репозиториям.

---

## Инфраструктура

| Компонент | Описание |
| --- | --- |
| Рабочая станция | macOS (MacBook Pro) |
| Бастион‑хост | `158.160.39.28` (вход по SSH) |
| Приватная подсеть | `10.0.0.0/24` |
| Сервер 1 | `10.0.0.25` |
| Сервер 2 | `10.0.0.12` |

Схема доступа:  
`macOS → Бастион (158.160.39.28) → Приватная подсеть (10.0.0.0/24) → Сервер 1 / Сервер 2`

> ⚠️ **Ограничение среды:** В Security Group отсутствует правило OUTBOUND в `0.0.0.0/0`. Это намеренно моделирует изолированную подсеть без прямого доступа к публичному интернету.

---

## Развёртывание и проверка

### Попытка обновления пакетов и установка Nginx

На обоих серверах была выполнена стандартная последовательность:

```bash
sudo apt update && \
sudo apt install -y nginx && \
sudo systemctl enable nginx && \
sudo systemctl start nginx

Проверка работоспособности Nginx
Несмотря на ошибки apt, сервис Nginx был подтверждён на обоих узлах запросом:

bash
curl -I http://localhost
Сервер 1 (10.0.0.25)
text
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Thu, 09 Jul 2026 17:47:41 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Thu, 09 Jul 2026 17:47:03 GMT
Connection: keep-alive
ETag: "6a4fde97-264"
Accept-Ranges: bytes
Сервер 2 (10.0.0.12)
text
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Thu, 09 Jul 2026 17:52:27 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Thu, 09 Jul 2026 17:52:19 GMT
Connection: keep-alive
ETag: "6a4fdfd3-264"
Accept-Ranges: bytes
![Проверка Nginx на сервере 1](artifacts/server1-curl.png)
![Проверка Nginx на сервере 2](artifacts/server2-curl.png)
✅ Статус: Nginx успешно запущен и отвечает HTTP‑кодом 200 OK на обоих серверах.

Анализ и выводы

SSH‑доступ через бастион подтверждён: реализована безопасная модель доступа к приватной подсети.
Работоспособность сервиса подтверждена независимо на двух узлах, несмотря на отсутствие доступа к публичным репозиториям.
Сетевые ограничения в изолированной среде блокируют apt и другие исходящие соединения — это важно учитывать при планировании деплоя.
Практический урок: В закрытых сетях следует использовать либо предварительно подготовленные образы ОС, либо локальные репозитории/пакеты, либо механизмы NAT/приватных зеркал.
Артефакты и дальнейшие шаги

Скриншоты/логи: Приложены в папке artifacts/ (или в виде листингов в отчёте).
Дальнейшие улучшения:
Добавить мониторинг (например, nginx-status + Prometheus).
Настроить локальный кэш/зеркало пакетов для изолированных подсетей.
Автоматизировать развёртывание через Ansible/Terraform.
НОВОЕ


# Дипломный проект DevOps: Развертывание отказоустойчивой инфраструктуры в Yandex Cloud

В данном репозитории содержатся файлы конфигурации Terraform для развертывания базовой инфраструктуры веб-сайта высокой доступности в соответствии с требованиями дипломного задания.

---

## Часть 1. Развертывание отказоустойчивого веб-сервера (Секция «Сайт»)

### Архитектурные решения:
1. **Сетевая топология (`network.tf`)**: Развернута единая виртуальная сеть VPC `main-network`. В целях обеспечения высокой доступности созданы две подсети в разных зонах доступности: `ru-central1-a` (приватный контур, диапазон `10.0.0.0/24`) и `ru-central1-b` (директива для распределения бэкендов, диапазон `10.0.1.0/24`).
2. **Отказоустойчивость серверов (`compute_instances.tf`)**: Развернуты две виртуальные машины под управлением ОС Ubuntu 22.04 LTS. Сервер `web-server-1` размещен в зоне `ru-central1-a`, а `web-server-2` — в зоне `ru-central1-b`. На каждом сервере инициализирован и настроен веб-сервер Nginx.
3. **Безопасность доступа (Bastion Host)**: Развернут защищенный хост `bastion-host` с публичным IP-адресом. Прямой доступ по SSH к веб-серверам из внешнего интернета полностью заблокирован на уровне групп безопасности (`security groups`). Доступ к приватным инстансам осуществляется строго по SSH через Bastion с использованием механизма проброса SSH-ключей (`SSH Agent Forwarding`).
4. **Балансировка трафика (`alb.tf`)**: Для распределения входящего трафика развернут L7 Application Load Balancer (`yandex_alb_load_balancer`). Создана целевая группа (`Target Group`), включающая обе ВМ. Настроен непрерывный мониторинг работоспособности серверов (`Healthcheck`) по протоколу HTTP на порт 80 и путь `/`.

---

### Конфигурационные файлы Terraform (.tf)

#### 1. Сетевая инфраструктура (`network.tf`)
```hcl
resource "yandex_vpc_network" "main" {
  name        = "main-network"
  description = "Main VPC network for devops course"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_route_table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "ru-central1-a" {
  name           = "subnet-ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
  zone           = "ru-central1-a"
  route_table_id = yandex_vpc_route_table.private_route_table.id
}

resource "yandex_vpc_subnet" "ru-central1-b" {
  name           = "subnet-ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone           = "ru-central1-b"
}
```

#### 2. Конфигурация серверов (`compute_instances.tf`)
```hcl
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

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
    subnet_id          = "e9bufivgub4je3slcc2n"
    nat                = true
    security_group_ids = ["enpbor7uoq6ddi0mhkbf"]
  }

  metadata = {
    ssh-keys = "ubuntu:\${file("~/.ssh/id_rsa.pub")}"
  }
}

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
    subnet_id          = "e9bufivgub4je3slcc2n"
    nat                = true
    security_group_ids = ["enp4kjqgm4t19ga4e120"]
  }

  metadata = {
    ssh-keys = "ubuntu:\${file("~/.ssh/id_rsa.pub")}"
  }
}

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
    nat                = true
    security_group_ids = ["enp4kjqgm4t19ga4e120"]
  }

  metadata = {
    ssh-keys = "ubuntu:\${file("~/.ssh/id_rsa.pub")}"
  }
}
```

#### 3. Настройка балансировщика трафика (`alb.tf`)
```hcl
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group"

  target {
    subnet_id  = "e9bufivgub4je3slcc2n"
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.ru-central1-b.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

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

resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-app-balancer"
  network_id         = yandex_vpc_network.main.id
  security_group_ids = ["enp4kjqgm4t19ga4e120"]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "e9bufivgub4je3slcc2n"
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
        external_ipv4_address {}
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

output "balancer_public_ip" {
  value = yandex_alb_load_balancer.web_alb.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}
```

---

### Тестирование доступности сайта через балансировщик трафика

После успешного выполнения команды `terraform apply` был выделен публичный IP-адрес балансировщика: **`158.160.212.97`**.

Запрос утилитой `curl` подтверждает корректную балансировку трафика и доступность веб-ресурса на бэкенд-нодах:

```bash
\$ curl -v http://158.160.212.97:80
*   Trying 158.160.212.97:80...
* Connected to 158.160.212.97 (158.160.212.97) port 80
> GET / HTTP/1.1
> Host: 158.160.212.97
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< server: ycalb
< date: Fri, 10 Jul 2026 14:22:59 GMT
< content-type: text/html
< content-length: 612
< last-modified: Thu, 09 Jul 2026 17:47:03 GMT
< etag: "6a4fde97-264"
< accept-ranges: bytes
< 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and working.</p>
</body>
</html>
* Connection #0 to host 158.160.212.97 left intact
```


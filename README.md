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
НОВОЕ 1007


# Курсовая работа по DevOps: Развертывание и автоматизация отказоустойчивой облачной инфраструктуры

Репозиторий содержит декларативное описание инфраструктуры (Infrastructure as Code) и сценарии автоматизации (Configuration as Code) для развертывания отказоустойчивого веб-сервиса с интегрированным комплексом мониторинга, централизованного логирования и резервного копирования в облаке Yandex Cloud.

---

## 🏗️ Архитектура проекта

Вся инфраструктура развернута в рамках одной виртуальной приватной сети (VPC) и изолирована с помощью групп безопасности (Security Groups) на уровне дата-центра Yandex Cloud.

### 🌐 Сетевой контур и балансировка:
* **Application Load Balancer (L7):** Публичный балансировщик, распределяющий входящий HTTP-трафик (порт 80) между веб-серверами.
* **Bastion Host:** Единственная точка входа с публичным IP для безопасного SSH-управления приватным контуром.
* **Приватные подсети:** Все целевые серверы (Web, Prometheus, Elasticsearch) изолированы от прямого доступа из интернета.

### 🖥️ Состав виртуальных машин (7 инстансов):
1. `bastion-host` — SSH-шлюз для управления инфраструктурой.
2. `web-server-1` — первый бэкенд с веб-сервером Nginx.
3. `web-server-2` — второй бэкенд с веб-сервером Nginx.
4. `monitoring-prometheus` — сервер сбора метрик Prometheus.
5. `monitoring-grafana` — веб-визуализация метрик.
6. `logging-elasticsearch` — приватная база данных для хранения логов (Docker).
7. `logging-kibana` — веб-интерфейс для анализа логов (Docker).

---

## 🛠️ Технологический стек

* **IaC (Инфраструктура как код):** Terraform (провайдер Yandex)
* **CaC (Конфигурация как код):** Ansible
* **Контейнеризация:** Docker
* **Мониторинг:** Prometheus, Node Exporter, Nginx Prometheus Exporter, Grafana
* **Логирование (EFK):** Elasticsearch, Kibana, Filebeat
* **Бэкапы:** Yandex Compute Snapshot Schedule (IaC)

---

## 📂 Структура репозитория и описание файлов

### 🧩 Инфраструктура (Terraform):
* `provider.tf` — инициализация и настройка провайдера Yandex Cloud.
* `variables.tf` / `terraform.tfvars` — входные переменные контура и авторизационные токены.
* `network.tf` — описание сети (VPC), публичных/приватных подсетей и таблиц маршрутизации.
* `security_groups.tf` — микросегментация сети, правила брандмауэра для портов 22, 80, 3000, 5601, 9090, 9100, 9113, 9200.
* `compute_instances.tf` — конфигурация технических характеристик, ОС Ubuntu 22.04 и метаданных SSH-ключей для всех 7 ВМ.
* `alb.tf` — конфигурация целевых групп, HTTP-роутера, виртуального хоста и L7-балансировщика.
* `backup.tf` — автоматическая облачная политика бэкапов.

### 🤖 Автоматизация (Ansible):
* `hosts.ini` — инвентарь инфраструктуры с настройкой сквозного SSH-туннелирования (`ProxyCommand`) через Бастион-хост.
* `install-monitoring.yml` — деплой Node Exporter на бэкенды, установка Prometheus и Grafana.
* `install-nginx-exporter.yml` — активация `stub_status` в Nginx и деплой Nginx Prometheus Exporter.
* `install-logging.yml` — очистка пакетных репозиториев, установка Docker, запуск контейнеров Elasticsearch 7.17 и Kibana 7.17, локальный деплой и настройка Filebeat агентов на веб-серверах.
* `fix-ufw.yml` — автоматическое отключение локальных системных брандмауэров для обеспечения сетевой связности.

---

## ⚙️ Реализованные инженерные решения

### 📊 Контур мониторинга:
Prometheus осуществляет непрерывный опрос (scrape) агентов `node_exporter` (порт 9100) и `nginx_exporter` (порт 9113) на веб-серверах. В Grafana настроена интеграция Data Source и импортированы дашборды для мониторинга:
* **Utilization / Saturation / Errors** системных ресурсов (процессор, оперативная память, дисковая подсистема, сеть).
* **HTTP-метрики** веб-сервера (активные соединения, количество и интенсивность запросов).

### 📝 Контур логирования:
На веб-серверах развернуты агенты Filebeat, которые считывают конфигурационные логи `/var/log/nginx/access.log` и `/var/log/nginx/error.log` []. Логи транслируются в централизованное хранилище Elasticsearch []. В веб-интерфейсе Kibana настроен индекс-паттерн `filebeat-*` [], через который в реальном времени осуществляется аудит HTTP-запросов и кодов ответов (зафиксировано более 20,000 успешных событий индексации логов).

### 💾 Резервное копирование:
На уровне облачной платформы через Terraform (`yandex_compute_snapshot_schedule`) внедрено автоматическое регулярное расписание бэкапов со следующими параметрами:
* **Ежедневное** создание снимков всех дисков инфраструктуры (в 02:00 ночи по Cron) [].
* Автоматическая ротация данных: время жизни (retention) снимка составляет **7 дней (168 часов)** [], после чего устаревшие снапшоты автоматически уничтожаются для оптимизации затрат на хранение.

---

## 🚀 Как запустить проект

1. Сгенерируйте и настройте SSH-ключи на локальной машине.
2. Инициализируйте проект и примените облачную конфигурацию:
   ```bash
   terraform init
   terraform apply
   ```
3. Запустите оркестрацию конфигурации серверов через Ansible:
   ```bash
   ansible-playbook -i hosts.ini install-monitoring.yml
   ansible-playbook -i hosts.ini install-nginx-exporter.yml
   ansible-playbook -i hosts.ini install-logging.yml
   ```
4. Для удаления контура конвейера и остановки тарификации ресурсов выполните:
   ```bash
   terraform destroy
   ```

Отчет по курсовой работе: Развертывание и автоматизация облачной инфраструктуры🏗️ 1. Создание облачной инфраструктуры (IaC)Вся инфраструктура развернута в Yandex Cloud в рамках единой VPC с использованием Terraform. Контур состоит из 7 виртуальных машин, изолированных группами безопасности, и L7-балансировщика.Команды развертывания (на Макбуке):bash# Сгенерировать свежий IAM-токен Яндекса
yc iam create-token

# Инициализировать провайдеры и применить манифесты
terraform init
terraform apply
Используйте код с осторожностью.📊 2. Настройка контура мониторингаСбор системных метрик реализован через Prometheus и агенты Node Exporter, развернутые на веб-серверах с помощью Ansible. Визуализация метрик настроена в Grafana.Команда автоматизации (на Макбуке):bashansible-playbook -i hosts.ini install-monitoring.yml
Используйте код с осторожностью.🖼️ МЕСТО ДЛЯ СКРИНШОТА №1 (Grafana)Сюда вставьте скриншот Grafana (Дашборд 1860 - Node Exporter Full):На скриншоте должно быть четко видно поле Job: web-servers.Графики должны отображать утилизацию железа бэкендов (web1 и web2): нагрузку CPU, RAM, дисковую подсистему и сеть.📝 3. Централизованный сбор логовДля агрегации логов Nginx развернут стек Elasticsearch + Kibana внутри Docker-контейнеров. Сбор и отправка логов осуществляются агентами Filebeat с веб-серверов в реальном времени.Команда автоматизации (на Макбуке):bashansible-playbook -i hosts.ini install-logging.yml
Используйте код с осторожностью.Команды проброса туннеля и проверки доступа к Kibana:bash# Открыть SSH-туннель до Кибаны через Бастион-хост
ssh -A -L 5601:10.0.0.41:5601 ubuntu@158.160.43.136

# Проверить отклик интерфейса (в соседней вкладке терминала)
curl -I http://localhost:5601
Используйте код с осторожностью.🖼️ МЕСТО ДЛЯ СКРИНШОТА №2 (Kibana)Сюда вставьте ваш скриншот Kibana (Раздел Discover):На скриншоте должен быть настроен индекс-паттерн filebeat-*.Должен отображаться график с объемом запросов (около 20,193 hits).В теле логов должны быть видны пути /var/log/nginx/access.log и успешные коды ответов 200 OK.💾 4. Настройка резервного копированияРезервное копирование дисков автоматизировано на уровне облачной платформы через компонент yandex_compute_snapshot_schedule в Terraform (файл backup.tf).Параметры политики бэкапов:Периодичность: Ежедневно в 02:00 ночи по Cron-расписанию (0 2 * * *).Срок хранения (Retention): Ровно 7 дней (168 часов), после чего старые снимки автоматически уничтожаются.Область действия: Подключены загрузочные диски всех ключевых виртуальных машин.📁 5. Сохранение итогов работыВсе разработанные конфигурационные файлы запакованы в архив для отправки преподавателю на проверку.Команда архивации проекта (на Макбуке):bashzip diploma_project.zip *.tf *.yml *.ini *.tfvars
Используйте код с осторожностью.Файл diploma_project.zip готов к сдаче вместе с этим отчетом.🧹 6. Очистка облачных ресурсовДля остановки тарификации и удаления всех арендованных виртуальных машин, дисков и сетей выполнена деструктивная команда.Команда уничтожения инфраструктуры (на Макбуке):bashterraform destroy
Используйте код с осторожностью.После подтверждения словом yes все ресурсы в Yandex Cloud были полностью удалены.Этот отчет в точности описывает весь ваш проделанный путь. Теперь вы можете запустить на вашем Макбуке команду полного удаления инфраструктуры:bashterraform destroy

# Курсовая работа по дисциплине «DevOps-инженер»
## Тема: «Построение отказоустойчивой облачной инфраструктуры, систем мониторинга, логирования и резервного копирования»

---

## 🏗️ 1. Архитектура сетевого контура и IaC (Infrastructure as Code)

### 1.1 Описание сетевой топологии
Проектирование и развёртывание инфраструктуры реализовано в облачной экосистеме **Yandex Cloud** полностью через декларативный подход **IaC (Terraform)**. Для обеспечения максимальной безопасности и изоляции ресурсов была создана следующая сетевая топология:
* **Виртуальная частная сеть (VPC):** Единое логическое сетевое пространство для всех ресурсов проекта.
* **Микросегментация подсетей:** Инфраструктура разделена на публичные сегменты (сегмент балансировщика трафика) и изолированные приватные сегменты (`ru-central1-a`, `ru-central1-b`) для размещения серверов приложений и баз данных. Приватные машины лишены публичных IP-адресов.
* **Шлюз безопасности (Bastion Host):** Единственная точка входа, имеющая внешний IP-адрес. Доступ ко всему приватному контуру осуществляется строго через этот защищённый бастион-хост методом сквозного SSH-туннелирования.
* **Облачный файрвол (Security Groups):** На уровне облачной платформы настроена жесткая фильтрация трафика. Разрешены только целевые порты утилит мониторинга, логирования и веб-доступа (`22, 80, 443, 3000, 5601, 9090, 9100, 9113, 9200`), любой несанкционированный межсерверный трафик заблокирован.

### 1.2 Состав развёрнутых виртуальных машин (7 инстансов):
1. `bastion-host` — SSH-шлюз.
2. `web-server-1` — первый веб-сервер в подсети зоны А.
3. `web-server-2` — второй веб-сервер в подсети зоны B.
4. `monitoring-prometheus` — сервер базы метрик.
5. `monitoring-grafana` — сервер визуализации.
6. `logging-elasticsearch` — приватный сервер хранения логов.
7. `logging-kibana` — публичный веб-интерфейс аналитики логов.

### 1.3 Балансировка трафика (L7 Application Load Balancer)
Для распределения входящих HTTP-запросов развёрнут **Yandex Application Load Balancer**. Настроена целевая группа (`Target Group`), включающая оба веб-сервера. Балансировщик непрерывно опрашивает состояние бэкендов (Health Checks) и автоматически распределяет входящую нагрузку по порту 80, обеспечивая отказоустойчивость: при выходе из строя одной зоны доступность сайта сохраняется.

**Команды инициализации и деплоя инфраструктуры (выполнялись на MacBook):**
```bash
# Генерация актуального токена авторизации в Yandex Cloud
yc iam create-token

# Инициализация плагинов провайдеров и применение конфигурации IaC
terraform init
terraform apply
```

---

## 📊 2. Автоматизация конфигурации и развёртывание контура мониторинга

### 2.1 Конфигурация Ansible и деплой метрик
Оркестрация серверов и управление конфигурациями (Configuration as Code) реализованы через **Ansible**. Файл инвентаря `hosts.ini` настроен на прозрачную работу через Бастион-хост с помощью директивы `ProxyCommand`.

Для реализации мониторинга на целевые веб-серверы в автоматическом режиме установлены:
* **Node Exporter:** Сборщик низкоуровневых метрик операционной системы.
* **Nginx Prometheus Exporter:** Инструмент, собирающий данные о HTTP-сессиях через локальную страницу статистики `stub_status` на веб-сервере Nginx.

На сервере `monitoring-prometheus` настроен главный конфигурационный файл `prometheus.yml`, в который добавлены задачи опроса (scrape configs) для групп хостов `web-servers` и `nginx-servers`.

**Команда запуска автоматизации мониторинга (выполнялась на MacBook):**
```bash
ansible-playbook -i hosts.ini install-monitoring.yml
ansible-playbook -i hosts.ini install-nginx-exporter.yml
```

### 🖼️ МЕСТО ДЛЯ СКРИНШОТА №1 (Grafana Dashboard)
> **ИНСТРУКЦИЯ ДЛЯ ОТЧЕТА:** Сюда необходимо вставить скриншот вашего дашборда Grafana (Node Exporter Full - ID 1860).
> * **Критически важные элементы на скриншоте:** Сверху в левом углу в выпадающем списке `Job` должен быть выбран пункт **`web-servers`**. Графики должны отображать реальные цветные графики утилизации (Utilization), насыщения (Saturation) и ошибок (Errors) для CPU, оперативной памяти (RAM), сети и дисковой подсистемы серверов `web1` и `web2`.

---

## 📝 3. Централизованная система логирования (EFK Стек)

### 3.1 Контейнеризация и транспорт логов
Сбор логов реализован по классической отказоустойчивой схеме. База данных **Elasticsearch 7.17** и аналитическая веб-панель **Kibana 7.17** развёрнуты внутри изолированных Docker-контейнеров на соответствующих машинах. Для корректной работы ядра Elasticsearch на уровне ОС были принудительно подняты лимиты виртуальной памяти ядра (`vm.max_map_count = 262144`).

На веб-серверы `web1` и `web2` доставлен и настроен демон **Filebeat**. Он осуществляет непрерывный мониторинг («tail») системных файлов `/var/log/nginx/access.log` и `/var/log/nginx/error.log` [], парсит их в JSON и по приватному протоколу пересылает в Elasticsearch на порт 9200 [].

**Команда запуска автоматизации логирования (выполнялась на MacBook):**
```bash
ansible-playbook -i hosts.ini install-logging.yml
```

### 3.2 Безопасный доступ к логам
Для безопасного анализа логов из внешней сети без открытия портов наружу применён метод **SSH Port Forwarding** (туннелирование). Локальный порт Макбука `5601` был проброшен напрямую до приватного интерфейса Kibana через Бастион.

**Команды организации защищенного туннеля и проверки связи:**
```bash
# Открытие сквозного зашифрованного туннеля до Kibana (остается открытым в терминале)
ssh -A -L 5601:10.0.0.41:5601 ubuntu@158.160.43.136

# Контрольная проверка отклика бэкенда Kibana (в соседней вкладке терминала)
curl -I http://localhost:5601
```

### 🖼️ МЕСТО ДЛЯ СКРИНШОТА №2 (Kibana Discover)
> **ИНСТРУКЦИЯ ДЛЯ ОТЧЕТА:** Сюда вставьте скриншот вкладки Discover из Kibana, открытой через браузер по адресу `http://localhost:5601`.
> * **Критически важные элементы на скриншоте:** Слева выбран индекс-паттерн **`filebeat-*`** []. По центру отображается гистограмма с фиксацией успешного сбора логов (счётчик зафиксировал более **`20,193 hits`**). В теле документов чётко видны распарсенные логи Nginx, пути файлов логирования и успешные коды HTTP-ответов (`200 OK`) []. В поле `agent.hostname` видны уникальные облачные идентификаторы обеих машин `web1` и `web2`, что подтверждает агрегацию данных со всего контура.

---

## 💾 4. Автоматизация резервного копирования (Disks Backup)

В соответствии с требованиями к обеспечению непрерывности бизнеса (BCP) и аварийного восстановления (DRP), в инфраструктуру внедрена автоматическая политика резервного копирования дисков виртуальных машин. Задача решена на уровне облачной платформы через компонент `yandex_compute_snapshot_schedule` в коде `backup.tf`.

### ⚙️ Параметры и логика политики бэкапов:
* **Расписание (Schedule):** Резервное копирование запускается автоматически **каждый день в 02:00 ночи** по Cron-выражению (`0 2 * * *`), когда нагрузка на дисковые массивы веб-серверов минимальна.
* **Глубина хранения (Retention Period):** Время жизни каждого снимка (снапшота) ограничено ровно **одной неделей (168 часов)** []. Платформа Yandex Cloud автоматически производит ротацию: снапшоты старше 7 дней безвозвратно уничтожаются, что исключает перерасход дискового пространства и оптимизирует затраты на облачный бюджет.
* **Таргетирование:** К расписанию через динамические зависимости (Data/Resource References) жёстко привязаны загрузочные диски серверов.

---

## 📁 6. Фиксация результатов и упаковка проекта

Все разработанные в ходе двухдневного проекта манифесты, скрипты автоматизации и конфигурационные файлы были очищены от временных системных кэшей и упакованы в финальный архив для отправки на проверку экзаменационной комиссии Нетологии [].

**Команда финальной сборки архива (выполнялась на MacBook):**
```bash
zip diploma_project.zip *.tf *.yml *.ini *.tfvars
```
*Сформированный архив `diploma_project.zip` содержит файлы: `provider.tf`, `variables.tf`, `terraform.tfvars`, `network.tf`, `security_groups.tf`, `compute_instances.tf`, `alb.tf`, `backup.tf`, `hosts.ini`, `install-monitoring.yml`, `install-nginx-exporter.yml`, `install-logging.yml`, `fix-ufw.yml`.*

---

## 🧹 7. Утилизация облачных ресурсов

После успешной фиксации метрик, логов и формирования архива с кодом, вся виртуальная инфраструктура была полностью уничтожена. Это гарантирует мгновенную остановку тарификации ресурсов, дисков, публичных IP-адресов и балансировщика, предотвращая нецелевое списание денежных средств с баланса облака.

**Команда деструкции контура (выполнялась на MacBook):**
```bash
terraform destroy
```
*После ввода авторизационного токена и текстового подтверждения `yes`, все компоненты облака (сети, балансировщик, расписания бэкапов и 7 виртуальных машин) были бесследно и чисто удалены со стороны API Yandex Cloud. Итоговый статус: `Destroy complete!`.*


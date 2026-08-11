# ==============================================================================
# 1. ГРУППА БЕЗОПАСНОСТИ ДЛЯ БАЛАНСИРОВЩИКА (ALB)
# ==============================================================================
resource "yandex_vpc_security_group" "alb" {
  name        = "alb-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Группа безопасности балансировщика: принимает публичный трафик"
}

# ALB: Входящий HTTP (80) из интернета
resource "yandex_vpc_security_group_rule" "alb_ingress_http" {
  security_group_binding = yandex_vpc_security_group.alb.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 80
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# ALB: Входящий HTTPS (443) из интернета
resource "yandex_vpc_security_group_rule" "alb_ingress_https" {
  security_group_binding = yandex_vpc_security_group.alb.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 443
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# ALB: Входящие проверки состояния (Healthchecks) от инфраструктуры Яндекса
resource "yandex_vpc_security_group_rule" "alb_ingress_healthchecks" {
  security_group_binding = yandex_vpc_security_group.alb.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 30000-65535
  v4_cidr_blocks         = ["198.18.235.0/24", "198.18.248.0/24"] # Служебные подсети YC ALB
}

# ALB: Исходящий трафик на веб-серверы
resource "yandex_vpc_security_group_rule" "alb_egress_to_web" {
  security_group_binding = yandex_vpc_security_group.alb.id
  direction              = "egress"
  protocol               = "TCP"
  port                   = 80
  security_group_id      = yandex_vpc_security_group.web.id
}


# ==============================================================================
# 2. ГРУППА БЕЗОПАСНОСТИ ДЛЯ БАСТИОН-ХОСТА
# ==============================================================================
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Группа безопасности для Бастион-хоста (единственная точка входа SSH)"
}

# Bastion: Разрешаем SSH (22) из интернета для администратора
resource "yandex_vpc_security_group_rule" "bastion_ssh" {
  security_group_binding = yandex_vpc_security_group.bastion.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["0.0.0.0/0"] # При желании можно сузить до домашнего IP
}

# Bastion: Исходящий трафик (разрешен любой для управления контуром)
resource "yandex_vpc_security_group_rule" "bastion_egress_any" {
  security_group_binding = yandex_vpc_security_group.bastion.id
  direction              = "egress"
  protocol               = "ANY"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}


# ==============================================================================
# 3. ГРУППА БЕЗОПАСНОСТИ ДЛЯ ВНУТРЕННИХ СЕРВЕРОВ (WEB, MON, LOG)
# ==============================================================================
resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Изолированная группа безопасности для веб-серверов и внутренних сервисов"
}

# WEB: Входящий HTTP (80) ТОЛЬКО от балансировщика (ALB)
resource "yandex_vpc_security_group_rule" "web_http_from_alb" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 80
  security_group_id      = yandex_vpc_security_group.alb.id
}

# WEB: Входящий SSH (22) ТОЛЬКО от Бастион-хоста (никаких подсетей 10.0.0.0/8)
resource "yandex_vpc_security_group_rule" "web_ssh_from_bastion" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 22
  security_group_id      = yandex_vpc_security_group.bastion.id
}

# MON: Доступ к Node Exporter (9100) внутри группы (для сбора метрик Прометеусом)
resource "yandex_vpc_security_group_rule" "node_exporter_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9100
  predefined_target      = "self_security_group"
}

# MON: Доступ к Nginx Exporter (9113) внутри группы (для сбора метрик Прометеусом)
resource "yandex_vpc_security_group_rule" "nginx_exporter_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9113
  predefined_target      = "self_security_group"
}

# MON: Входящий Prometheus (9090) внутри группы для межсервисного взаимодействия
resource "yandex_vpc_security_group_rule" "prometheus_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9090
  predefined_target      = "self_security_group"
}

# MON: Публичный доступ к Grafana (3000) из интернета
resource "yandex_vpc_security_group_rule" "grafana_web" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 3000
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# LOG: Доступ к Elasticsearch (9200) внутри группы (для отправки логов Filebeat)
resource "yandex_vpc_security_group_rule" "elastic_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9200
  predefined_target      = "self_security_group"
}

# LOG: Публичный доступ к Kibana (5601) из интернета
resource "yandex_vpc_security_group_rule" "kibana_web" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 5601
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# WEB: Весь исходящий трафик (для скачивания пакетов, обновлений и образов Docker)
resource "yandex_vpc_security_group_rule" "web_egress_any" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "egress"
  protocol               = "ANY"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

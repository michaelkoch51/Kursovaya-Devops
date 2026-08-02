resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Группа безопасности для Бастион-хоста"
}

resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Общая группа безопасности для внутренних сервисов"
}

# Bastion: разрешаем SSH из интернета
resource "yandex_vpc_security_group_rule" "bastion_ssh" {
  security_group_binding = yandex_vpc_security_group.bastion.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Bastion: весь исходящий трафик
resource "yandex_vpc_security_group_rule" "bastion_egress_any" {
  security_group_binding = yandex_vpc_security_group.bastion.id
  direction              = "egress"
  protocol               = "ANY"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Web: внутренний SSH с Бастиона
resource "yandex_vpc_security_group_rule" "web_ssh_from_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
}

# Web: HTTP из интернета
resource "yandex_vpc_security_group_rule" "web_http" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 80
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Web: HTTPS из интернета
resource "yandex_vpc_security_group_rule" "web_https" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 443
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Web: весь исходящий трафик
resource "yandex_vpc_security_group_rule" "web_egress_any" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "egress"
  protocol               = "ANY"
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Grafana: порт 3000 из интернета
resource "yandex_vpc_security_group_rule" "grafana_web" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 3000
  v4_cidr_blocks         = ["0.0.0.0/0"]
}

# Prometheus: порт 9090 из внутренних подсетей
resource "yandex_vpc_security_group_rule" "prometheus_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9090
  v4_cidr_blocks         = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
}

# Внутренний трафик внутри группы (self_security_group)
resource "yandex_vpc_security_group_rule" "internal_all" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  predefined_target      = "self_security_group"
}

# Nginx Exporter: порт 9113 из внутренних подсетей
resource "yandex_vpc_security_group_rule" "nginx_exporter" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9113
  v4_cidr_blocks         = ["10.0.0.0/8"]
}

# Elasticsearch: порт 9200 из внутренних подсетей
resource "yandex_vpc_security_group_rule" "elastic_internal" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 9200
  v4_cidr_blocks         = ["10.0.0.0/8"]
}

# Kibana: порт 5601 из интернета
resource "yandex_vpc_security_group_rule" "kibana_web_fixed" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  protocol               = "TCP"
  port                   = 5601
  v4_cidr_blocks         = ["0.0.0.0/0"]
}


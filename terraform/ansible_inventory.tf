resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/hosts.ini"
  
  content = <<EOT
[web]
web1 ansible_host=${yandex_compute_instance.web1.network_interface.0.ip_address}
web2 ansible_host=${yandex_compute_instance.web2.network_interface.0.ip_address}

[prometheus]
elasticsearch_node ansible_host=${yandex_compute_instance.prometheus.network_interface.0.ip_address}

[grafana]
grafana_node ansible_host=${yandex_compute_instance.grafana.network_interface.0.ip_address}

[elasticsearch]
elasticsearch_node ansible_host=${yandex_compute_instance.elasticsearch.network_interface.0.ip_address}

[kibana]
kibana_node ansible_host=${yandex_compute_instance.kibana.network_interface.0.ip_address}

[all:vars]
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -A -W %h:%p -q ubuntu@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
EOT
}


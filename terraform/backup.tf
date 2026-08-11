resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name        = "daily-snapshot-schedule"
  description = "Ежедневное резервное копирование всех 7 виртуальных машин"

  schedule_policy {
    expression = "0 2 * * *" # Каждый день в 2 часа ночи
  }

  retention_period = "168h" # Снимки хранятся ровно неделю (7 дней)

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web1.boot_disk.0.disk_id,
    yandex_compute_instance.web2.boot_disk.0.disk_id,
    yandex_compute_instance.prometheus.boot_disk.0.disk_id,
    yandex_compute_instance.grafana.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id
  ]
}


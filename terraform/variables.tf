variable "folder_id" {
  description = "ID каталога в Yandex Cloud"
  type        = string
}

variable "iam_token" {
  description = "IAM‑токен"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "ID подсети, где будут созданы виртуалки"
  type        = string
}

variable "bastion_sg_id" {
  description = "ID security group для bastion (enpbor7uoq6ddi0mhkbf)"
  type        = string
}

variable "web_sg_id" {
  description = "ID security group для web (enp4kjqgm4t19ga4e120)"
  type        = string
}


terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.196.0"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
  zone      = "ru-central1"
  token     = var.iam_token
}


variable "ya_token" {
  type = string
  description = "Yandex Cloud security OAuth token"
}

variable "ya_cloud_id" {
  type = string
  description = "Yandex Cloud ID where resources will be created"
}

variable "ya_folder_id" {
  type = string
  description = "Yandex Cloud Folder ID where resources will be created"
}

variable "ya_zone" {
  type = string
  default = "ru-central1-a"
}

variable "public_subnet" {
  type = list
  default = ["192.168.10.0/24"]
}

variable "private_subnet" {
  type = list
  default = ["192.168.20.0/24"]
}

variable "nat_gw" {
  type = string
  default = "192.168.10.254"
}

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

variable "ya_zone_a" {
  type = string
  default = "ru-central1-a"
}

variable "ya_zone_b" {
  type = string
  default = "ru-central1-b"
}
variable "ya_zone_c" {
  type = string
  default = "ru-central1-c"
}

variable "public_subnet_a" {
  type = list
  default = ["192.168.10.0/24"]
}
variable "public_subnet_b" {
  type = list
  default = ["192.168.20.0/24"]
}
variable "public_subnet_c" {
  type = list
  default = ["192.168.30.0/24"]
}

variable "private_subnet_a" {
  type = list
  default = ["192.168.40.0/24"]
}
variable "private_subnet_b" {
  type = list
  default = ["192.168.50.0/24"]
}
variable "private_subnet_c" {
  type = list
  default = ["192.168.60.0/24"]
}

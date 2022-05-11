resource "yandex_vpc_network" "vpc" {
  name = "network"
}

resource "yandex_vpc_subnet" "public" {
  name = "public"
  zone           = var.ya_zone
  network_id     = "${yandex_vpc_network.vpc.id}"
  v4_cidr_blocks = var.public_subnet
}

resource "yandex_vpc_subnet" "private" {
  name = "private"
  zone           = var.ya_zone
  network_id     = "${yandex_vpc_network.vpc.id}"
  v4_cidr_blocks = var.private_subnet
  route_table_id = "${yandex_vpc_route_table.nat-rt.id}"
}

resource "yandex_vpc_route_table" "nat-rt" {
  network_id = "${yandex_vpc_network.vpc.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_gw
  }
}

resource "yandex_iam_service_account" "web" {
  name        = "manage-web"
  description = "service account to manage web"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.ya_folder_id
  role                = "editor"
  members              = ["serviceAccount:${yandex_iam_service_account.web.id}"]
  depends_on = [yandex_iam_service_account.web]
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = "${yandex_iam_service_account.web.id}"
  description        = "static access key for object storage"
  depends_on = [yandex_iam_service_account.web]
}

resource "yandex_storage_bucket" "bucket-web" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "bucket-web"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "str-web" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "${yandex_storage_bucket.bucket-web.bucket}"
  content_type = "image/jpeg"
  acl = "public-read" 
  key = "9_may.jpg"
  source = "/home/nikolay/15_yandex-terraform/9_may.jpg"
}

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}

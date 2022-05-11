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

resource "yandex_lb_target_group" "tg-web" {
  name      = "target-group"

  dynamic "target" {
    for_each = "${yandex_compute_instance_group.web-group.instances}"
    content {
      subnet_id = "${target.value.network_interface.0.subnet_id}"
      address   = "${target.value.network_interface.0.ip_address}"
    }
  }  
}
resource "yandex_lb_network_load_balancer" "internal-lb" {
  name = "internal-load-balancer"
  type = "internal"

  listener {
    name = "my-listener"
    port = 80
    internal_address_spec {
      subnet_id = "${yandex_vpc_subnet.public.id}"
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tg-web.id}"
    
    healthcheck {
      name = "http"
      timeout = 1
      healthy_threshold = 2
      unhealthy_threshold = 5
      http_options {
        port = 80
        path = "/ping"
      }
    }
  }
}

resource "yandex_compute_instance_group" "web-group" {
  name = "web-group"
  folder_id = var.ya_folder_id
  service_account_id  = "${yandex_iam_service_account.web.id}"
  depends_on = [yandex_iam_service_account.web]
  instance_template {
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      initialize_params {
        image_id = "fd80mrhj8fl2oe87o4e1"
        type = "network-ssd"
      }
    }    
    network_interface {
      network_id = "${yandex_vpc_network.vpc.id}"    
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
      nat = true
    }
    metadata = {
      user-data = "${file("/home/nikolay/15_yandex-terraform/15_2/meta.yaml")}"
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = [var.ya_zone]
  }

  deploy_policy {
    max_unavailable = 0
    max_expansion   = 1
  }
    
  health_check {
    interval = 10
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 5
    http_options {
      port = 80
      path = "/"
    }
  }    
}

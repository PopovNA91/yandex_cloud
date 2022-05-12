resource "yandex_iam_service_account" "kub_admin" {
  name        = "admin-kub"
  description = "service account to admin kub"
}

resource "yandex_resourcemanager_folder_iam_binding" "kub_admin" {
  folder_id = var.ya_folder_id
  role                = "admin"
  members              = ["serviceAccount:${yandex_iam_service_account.kub_admin.id}"]
  depends_on = [yandex_iam_service_account.kub_admin]
}

resource "yandex_iam_service_account" "kub_manager" {
  name        = "manager-kub"
  description = "service account to manage kub"
}

resource "yandex_resourcemanager_folder_iam_binding" "kub_editor" {
  folder_id = var.ya_folder_id
  role                = "editor"
  members              = ["serviceAccount:${yandex_iam_service_account.kub_manager.id}"]
  depends_on = [yandex_iam_service_account.kub_manager]
}

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}

resource "yandex_kubernetes_cluster" "cluster_netology" {
  name        = "cluster_netology"
  description = "cluster for fourth lesson"

  network_id = "${yandex_vpc_network.vpc.id}"

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = var.ya_zone_a
        subnet_id = "${yandex_vpc_subnet.public_a.id}"
      }

      location {
        zone      = var.ya_zone_b
        subnet_id = "${yandex_vpc_subnet.public_b.id}"
      }

      location {
        zone      = var.ya_zone_c
        subnet_id = "${yandex_vpc_subnet.public_c.id}"
      }
    }

    version   = "1.21"
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "15:00"
        duration   = "3h"
      }

      maintenance_window {
        day        = "friday"
        start_time = "10:00"
        duration   = "4h30m"
      }
    }
  }

  service_account_id      = "${yandex_iam_service_account.kub_admin.id}"
  node_service_account_id = "${yandex_iam_service_account.kub_manager.id}"
  
  release_channel = "STABLE"
  
   kms_provider {
    key_id = "${yandex_kms_symmetric_key.key-a.id}"
  }
}

resource "yandex_kubernetes_node_group" "node_group_netology" {
  cluster_id  = "${yandex_kubernetes_cluster.cluster_netology.id}"
  name        = "node_group_netology"
  description = "node group for fourth lesson"
  version     = "1.21"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.public_a.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    auto_scale {
      min = 3
      max = 6
      initial = 3
    }
  }

  allocation_policy {
    location {
      zone = var.ya_zone_a
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }
}

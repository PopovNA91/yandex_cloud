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

resource "yandex_mdb_mysql_cluster" "cluster_mysql" {
  name        = "db-15-4"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.vpc.id
  version     = "8.0"

  resources {
    resource_preset_id = "b1.medium"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  database {
    name = "netology_db"
  }

  maintenance_window {
    type = "ANYTIME"
  }
  
  backup_window_start {
  hours = 23
  minutes = 59
  }

  user {
    name     = "netology"
    password = "netology"
    permission {
      database_name = "netology_db"
      roles         = ["ALL"]
    }
  }

  host {
    zone      = "ru-central1-a"
    name      = "na-1"
    subnet_id = yandex_vpc_subnet.private_a.id
  }
  host {
    zone      = "ru-central1-b"
    name      = "na-2"
    subnet_id = yandex_vpc_subnet.private_b.id
  }
  host {
    zone      = "ru-central1-c"
    name      = "na-3"
    subnet_id = yandex_vpc_subnet.private_c.id
  }
  host {
    zone                    = "ru-central1-a"
    name                    = "nb-1"
    replication_source_name = "na-1"
    subnet_id               = yandex_vpc_subnet.private_a.id
  }
  host {
    zone                    = "ru-central1-b"
    name                    = "nb-2"
    replication_source_name = "na-2"
    subnet_id               = yandex_vpc_subnet.private_b.id
  }
  host {
    zone                    = "ru-central1-c"
    name                    = "nb-3"
    replication_source_name = "na-3"
    subnet_id               = yandex_vpc_subnet.private_c.id
  }

}

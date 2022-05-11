resource "yandex_compute_instance" "vm-1" {
  name = "vm-1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8p6amfv1d4ehbfjjrl"
      type = "network-ssd"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet_1.id}"
    nat       = true
  }

  metadata = {
    user-data = "${file("~/yandex-cloud-terraform/meta.txt")}"
  }
}

resource "yandex_compute_instance" "vm-2" {
  name = "vm-2"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8p6amfv1d4ehbfjjrl"
      type = "network-ssd"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet_2.id}"
  }

  metadata = {
    user-data = "${file("~/yandex-cloud-terraform/meta.txt")}"
  }
}

resource "yandex_compute_instance" "nat" {
  name = "nat-instance"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      type = "network-ssd"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet_1.id}"
    ip_address = "192.168.10.254"
    nat       = true
  }

  metadata = {
    user-data = "${file("~/yandex-cloud-terraform/meta.txt")}"
  }
}



resource "yandex_vpc_network" "vpc" {
  name = "network"
}

resource "yandex_vpc_subnet" "subnet_1" {
  name = "public"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.vpc.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet_2" {
  name = "private"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.vpc.id}"
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = "${yandex_vpc_route_table.nat-rt.id}"
}

resource "yandex_vpc_route_table" "nat-rt" {
  network_id = "${yandex_vpc_network.vpc.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

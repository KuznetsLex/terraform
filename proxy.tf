resource "random_password" "basic_auth_password" {
  length  = 16
  special = false
}

locals {
  cloud_init_proxy = templatefile("${path.module}/cloud-init-proxy.yaml", {
    basic_auth_user     = "admin"
    basic_auth_password = random_password.basic_auth_password.result
    alb_endpoint        = yandex_alb_load_balancer.alb.listener[0].endpoint[0].address[0].internal_ipv4_address[0].address
  })
}

resource "yandex_vpc_address" "proxy_static_ip" {
  name = "proxy-static-ip"
  
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_compute_instance" "nginx_proxy" {
  name        = "nginx_proxy"
  zone        = var.zone
  platform_id = "standard-v2"
  hostname    = "proxy"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 5
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.proxy_subnet_a.id
    security_group_ids = [yandex_vpc_security_group.proxy_sg.id]
    nat                = true
    nat_ip_address     = yandex_vpc_address.proxy_static_ip.external_ipv4_address[0].address
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
    user-data = local.cloud_init_proxy
  }

  depends_on = [yandex_alb_load_balancer.alb]
}
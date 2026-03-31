resource "yandex_alb_load_balancer" "alb" {
  name               = "web-alb"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_subnet_a.id
    }
    
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public_subnet_b.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        internal_ipv4_address {
          subnet_id = yandex_vpc_subnet.public_subnet_a.id
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }
  }

  depends_on = [
    yandex_alb_virtual_host.virtual_host,
    yandex_alb_backend_group.backend_group,
    yandex_alb_target_group.target_group
  ]
}

resource "yandex_alb_target_group" "target_group" {
  name = "web-servers-tg"

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
    ip_address = yandex_compute_instance.vm1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_b.id
    ip_address = yandex_compute_instance.vm2.network_interface[0].ip_address
  }

  depends_on = [
    yandex_compute_instance.vm1,
    yandex_compute_instance.vm2
  ]
}

resource "yandex_alb_backend_group" "backend_group" {
  name = "web-servers-bg"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.target_group.id]

    healthcheck {
      timeout             = "2s"
      interval            = "5s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/health"
      }
    }
  }
}

resource "yandex_alb_http_router" "http_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "virtual_host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.http_router.id
  
  route {
    name = "web-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend_group.id
        timeout          = "60s"
      }
    }
  }
}

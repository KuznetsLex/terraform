output "basic_auth_credentials" {
  description = "Basic auth credentials for proxy"
  value = {
    username = "admin"
    password = random_password.basic_auth_password.result
  }
  sensitive = true 
}

output "debug_info" {
  value = {
    proxy_static_ip = yandex_vpc_address.proxy_static_ip.external_ipv4_address[0].address
    alb_ip   = yandex_alb_load_balancer.alb.listener[0].endpoint[0].address[0].internal_ipv4_address[0].address
    vm1_ip   = yandex_compute_instance.vm1.network_interface[0].ip_address
    vm2_ip   = yandex_compute_instance.vm2.network_interface[0].ip_address
  }
}
output "controllers_dns" {
  value = "${openstack_compute_instance_v2.controllers.*.network.0.fixed_ip_v4}"
}

output "workers_dns" {
  value = "${openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4}"
}

output "controllers_ipv4" {
  value = ["${openstack_compute_instance_v2.controllers.*.network.0.fixed_ip_v4}"]
}

output "controllers_ipv6" {
  value = ["${openstack_compute_instance_v2.controllers.*.network.0.fixed_ip_v6}"]
}

output "workers_ipv4" {
  value = ["${openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4}"]
}

output "workers_ipv6" {
  value = ["${openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v6}"]
}

# # Worker DNS records
# resource "openstack_dns_recordset_v2" "workers" {

#   # DNS zone where record should be created
#   zone_id = "${var.dns_zone}"

#   name  = "${var.cluster_name}-workers"
#   type  = "A"
#   ttl   = 300
#   records = "${openstack_compute_flavor_v2.workers.*.ipv4_address}"
# }

# Worker droplet instances
resource "openstack_compute_instance_v2" "workers" {
  count = "${var.worker_count}"

  name   = "${var.cluster_name}-worker-${count.index}"
  region = "${var.region}"

  image = "${var.image}"
  flavor_id  = "${var.worker_type}"

  user_data = "${data.ct_config.worker_ign.rendered}"

  key_pair        = "my_key_pair_name"
  security_groups = ["default"]

  network {
    name = "Ext-Network"
  }
}


# Worker Container Linux Config
data "template_file" "worker_config" {
  template = "${file("${path.module}/cl/worker.yaml.tmpl")}"

  vars = {
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
  }
}

data "ct_config" "worker_ign" {
  content      = "${data.template_file.worker_config.rendered}"
  pretty_print = false
  snippets     = ["${var.worker_clc_snippets}"]
}

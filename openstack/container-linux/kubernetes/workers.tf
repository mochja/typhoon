# # Worker DNS records
# resource "openstack_dns_recordset_v2" "workers" {

#   # DNS zone where record should be created
#   zone_id = "${var.dns_zone}"

#   name  = "${var.cluster_name}-workers"
#   type  = "A"
#   ttl   = 300
#   records = "${openstack_compute_flavor_v2.workers.*.ipv4_address}"
# }

data "openstack_compute_flavor_v2" "worker_flavor" {
  name = "${var.worker_type}"
}

# Worker droplet instances
resource "openstack_compute_instance_v2" "workers" {
  count = "${var.worker_count}"

  name   = "${var.cluster_name}-worker-${count.index}"
  region = "${var.region}"

  image_id = "${data.openstack_images_image_v2.controller_image.id}"
  flavor_id  = "${data.openstack_compute_flavor_v2.worker_flavor.id}"

  user_data = "${data.ct_config.worker_ign.rendered}"

  key_pair        = "mbpro-nemo"
  security_groups = ["default"]

  network {
    name = "Ext-Net"
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

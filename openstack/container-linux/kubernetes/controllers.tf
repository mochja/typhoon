# # Controller Instance DNS records
# resource "digitalocean_record" "controllers" {
#   count = "${var.controller_count}"

#   # DNS zone where record should be created
#   domain = "${var.dns_zone}"

#   # DNS record (will be prepended to domain)
#   name = "${var.cluster_name}"
#   type = "A"
#   ttl  = 300

#   # IPv4 addresses of controllers
#   value = "${element(digitalocean_droplet.controllers.*.ipv4_address, count.index)}"
# }

# # Discrete DNS records for each controller's private IPv4 for etcd usage
# resource "digitalocean_record" "etcds" {
#   count = "${var.controller_count}"

#   # DNS zone where record should be created
#   domain = "${var.dns_zone}"

#   # DNS record (will be prepended to domain)
#   name = "${var.cluster_name}-etcd${count.index}"
#   type = "A"
#   ttl  = 300

#   # private IPv4 address for etcd
#   value = "${element(digitalocean_droplet.controllers.*.ipv4_address_private, count.index)}"
# }

data "openstack_images_image_v2" "controller_image" {
  name = "${var.image}"
  most_recent = true
}

data "openstack_compute_flavor_v2" "controller_flavor" {
  name = "${var.controller_type}"
}

# Controller droplet instances
resource "openstack_compute_instance_v2" "controllers" {
  count = "${var.controller_count}"

  name   = "${var.cluster_name}-controller-${count.index}"
  region = "${var.region}"

  image_id = "${data.openstack_images_image_v2.controller_image.id}"
  flavor_id  = "${data.openstack_compute_flavor_v2.controller_flavor.id}"

  user_data = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"

  key_pair        = "mbpro-nemo"
  security_groups = ["default"]

  network {
    name = "Ext-Net"
  }
}

# Controller Container Linux Config
data "template_file" "controller_config" {
  count = "${var.controller_count}"

  template = "${file("${path.module}/cl/controller.yaml.tmpl")}"

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"

    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster  = "${join(",", formatlist("%s=https://%s:2380", null_resource.repeat.*.triggers.name, null_resource.repeat.*.triggers.domain))}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
  }
}

# Horrible hack to generate a Terraform list of a desired length without dependencies.
# Ideal ${repeat("etcd", 3) -> ["etcd", "etcd", "etcd"]}
resource null_resource "repeat" {
  count = "${var.controller_count}"

  triggers {
    name   = "etcd${count.index}"
    domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"
  }
}

data "ct_config" "controller_ign" {
  count        = "${var.controller_count}"
  content      = "${element(data.template_file.controller_config.*.rendered, count.index)}"
  pretty_print = false

  snippets = ["${var.controller_clc_snippets}"]
}

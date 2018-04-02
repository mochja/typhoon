# Self-hosted Kubernetes assets (kubeconfig, manifests)
module "bootkube" {
  source = "git::https://github.com/poseidon/terraform-render-bootkube.git?ref=5f3546b66ffb9946b36e612537bb6a1830ae7746"

  cluster_name          = "${var.cluster_name}"
  api_servers           = ["${format("%s.%s", var.cluster_name, var.dns_zone)}"]
  # etcd_servers          = "${digitalocean_record.etcds.*.fqdn}"
  etcd_servers          = "${digitalocean_droplet.controllers.*.ipv4_address_private}"
  asset_dir             = "${var.asset_dir}"
  networking            = "flannel"
  network_mtu           = 1440
  pod_cidr              = "${var.pod_cidr}"
  service_cidr          = "${var.service_cidr}"
  cluster_domain_suffix = "${var.cluster_domain_suffix}"
}

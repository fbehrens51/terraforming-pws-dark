output "mjb_private_ip" {
  value = "${element(concat(module.sjb_bootstrap.eni_ips, list("")), 0)}"
}

output "mjb_private_key" {
  value     = "${module.control_plane_host_key_pair.private_key_pem}"
  sensitive = true
}

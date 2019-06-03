output "mjb_private_ip" {
  value = "${module.bootstrap_control_plane.private_ip}"
}

output "mjb_private_key" {
  value     = "${module.control_plane_host_key_pair.private_key_pem}"
  sensitive = true
}

output "bucket" {
  value = "${element(concat(aws_s3_bucket.ops_manager_bucket.*.bucket, list("")), 0)}"
}

output "public_ip" {
  value = "${element(concat(aws_eip.ops_manager_unattached.*.public_ip, list("")), 0)}"
}

output "om_eni_id" {
  value = "${aws_network_interface.ops_manager_unattached.id}"
}

output "om_eip_allocation_id" {
  value = "${element(concat(aws_eip.ops_manager_unattached.*.id, list("")), 0)}"
}

output "security_group_id" {
  value = "${element(concat(aws_security_group.ops_manager_security_group.*.id, list("")), 0)}"
}

output "ssh_private_key" {
  value = "${element(concat(tls_private_key.ops_manager.*.private_key_pem, list("")), 0)}"
}

output "ssh_public_key_name" {
  value = "${element(concat(aws_key_pair.ops_manager.*.key_name, list("")), 0)}"
}

output "ssh_public_key" {
  value = "${element(concat(aws_key_pair.ops_manager.*.public_key, list("")), 0)}"
}

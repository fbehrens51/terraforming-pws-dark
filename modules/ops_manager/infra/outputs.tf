output "bucket" {
  value = aws_s3_bucket.ops_manager_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.ops_manager_bucket.arn
}

output "director_blobstore_bucket" {
  value = aws_s3_bucket.director_blobstore_bucket.bucket
}

output "director_blobstore_bucket_arn" {
  value = aws_s3_bucket.director_blobstore_bucket.arn
}

output "ip" {
  value = element(
    concat(
      aws_eip.ops_manager_unattached.*.public_ip,
      flatten(aws_network_interface.ops_manager_unattached.*.private_ips),
      [""],
    ),
    0,
  )
}

output "om_eni_id" {
  value = element(
    concat(aws_network_interface.ops_manager_unattached.*.id, [""]),
    0,
  )
}

output "om_eip_allocation" {
  value = aws_eip.ops_manager_unattached
}

output "security_group_id" {
  value = element(
    concat(aws_security_group.ops_manager_security_group.*.id, [""]),
    0,
  )
}


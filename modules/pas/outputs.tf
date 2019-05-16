# ========= Subnets ============================================================

output "pas_subnet_ids" {
  value = ["${aws_subnet.pas_subnets.*.id}"]
}

output "pas_subnet_availability_zones" {
  value = ["${aws_subnet.pas_subnets.*.availability_zone}"]
}

output "pas_subnet_cidrs" {
  value = ["${aws_subnet.pas_subnets.*.cidr_block}"]
}

output "pas_subnet_gateways" {
  value = ["${data.template_file.pas_subnet_gateways.*.rendered}"]
}

output "services_subnet_ids" {
  value = ["${aws_subnet.services_subnets.*.id}"]
}

output "services_subnet_availability_zones" {
  value = ["${aws_subnet.services_subnets.*.availability_zone}"]
}

output "services_subnet_cidrs" {
  value = ["${aws_subnet.services_subnets.*.cidr_block}"]
}

output "services_subnet_gateways" {
  value = ["${data.template_file.services_subnet_gateways.*.rendered}"]
}

# ========= Buckets ============================================================

output "pas_buildpacks_bucket" {
  value = "${aws_s3_bucket.buildpacks_bucket.bucket}"
}

output "pas_droplets_bucket" {
  value = "${aws_s3_bucket.droplets_bucket.bucket}"
}

output "pas_packages_bucket" {
  value = "${aws_s3_bucket.packages_bucket.bucket}"
}

output "pas_resources_bucket" {
  value = "${aws_s3_bucket.resources_bucket.bucket}"
}

output "pas_buildpacks_backup_bucket" {
  value = "${element(concat(aws_s3_bucket.buildpacks_backup_bucket.*.bucket, list("")), 0)}"
}

output "pas_droplets_backup_bucket" {
  value = "${element(concat(aws_s3_bucket.droplets_backup_bucket.*.bucket, list("")), 0)}"
}

output "pas_packages_backup_bucket" {
  value = "${element(concat(aws_s3_bucket.packages_backup_bucket.*.bucket, list("")), 0)}"
}

output "pas_resources_backup_bucket" {
  value = "${element(concat(aws_s3_bucket.resources_backup_bucket.*.bucket, list("")), 0)}"
}

output "isoseg_target_groups" {
  value = [
    "${element(concat(aws_lb_target_group.isoseg_80.*.name, list("")), 0)}",
    "${element(concat(aws_lb_target_group.isoseg_443.*.name, list("")), 0)}",
    "${element(concat(aws_lb_target_group.isoseg_4443.*.name, list("")), 0)}",
  ]
}

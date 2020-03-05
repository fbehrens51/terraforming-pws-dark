variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "control_plane_host_key_pair_name" {
}

variable "terraform_bucket_name" {
}

variable "transfer_bucket_promotion_account_arn"{}

variable "terraform_region" {
}

variable "rds_db_username" {
}

variable "rds_instance_class" {
}

variable "singleton_availability_zone" {
}

variable "sjb_egress_rules" {
  type = list(object({ port = string, protocol = string, cidr_blocks = string }))
}

variable "sjb_ingress_rules" {
  type = list(object({ port = string, protocol = string, cidr_blocks = string }))
}

# variable "remote_state_bucket" {}
# variable "remote_state_region" {}
# variable "rds_db_username" {}
# variable "rds_instance_class" {}

# variable "env_name" {}

variable "nat_instance_type" {
  default = "t2.small"
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "tags" {
  type = map(string)
}

variable "vpce_interface_prefix" {}

# variable "s3_endpoint" {}
# variable "ec2_endpoint" {}
# variable "elb_endpoint" {}
# variable "region" {}

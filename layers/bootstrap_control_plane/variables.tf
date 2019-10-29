variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "control_plane_host_key_pair_name" {}
variable "rds_db_username" {}
variable "rds_instance_class" {}

variable "singleton_availability_zone" {}

variable "sjb_egress_rules" {
  type = "list"
}

variable "sjb_ingress_rules" {
  type = "list"
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
  type = "list"
}

variable "internetless" {}

variable "tags" {
  type = "map"
}

# variable "s3_endpoint" {}
# variable "ec2_endpoint" {}
# variable "elb_endpoint" {}
# variable "region" {}


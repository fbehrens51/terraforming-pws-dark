variable "remote_state_bucket" {}
variable "remote_state_region" {}

variable "user_data_path" {}
variable "instance_type" {}

variable "product_blobs_s3_bucket" {}
variable "product_blobs_s3_region" {}

variable "tags" {
  type = "map"
}

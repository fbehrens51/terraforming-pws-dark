variable "name" {
  description = "Cannot be longer than 10 characters.  The name will be used to derive the placement tag by replacing spaces with underscores and lowercasing the entire string.  The placement tag is available in the placement_tag output."
}

variable "mirror_bucket" {}

variable "pivnet_api_token" {}

variable "s3_access_key_id" {}
variable "s3_secret_access_key" {}
variable "s3_auth_type" {}
variable "s3_endpoint" {}
variable "region" {}

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "singleton_availability_zone" {}

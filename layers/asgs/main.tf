variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}

data "aws_s3_bucket_objects" "blocked-cidr-objects" {
  bucket = local.secrets_bucket_name
  prefix = "blocked-cidrs/"
}

data "aws_s3_bucket_object" "blocked-cidrs" {
  count  = length(data.aws_s3_bucket_objects.blocked-cidr-objects.keys)
  key    = element(data.aws_s3_bucket_objects.blocked-cidr-objects.keys, count.index)
  bucket = data.aws_s3_bucket_objects.blocked-cidr-objects.bucket
}

data "aws_s3_bucket_objects" "allowed-cidr-objects" {
  bucket = local.secrets_bucket_name
  prefix = "allowed-cidrs/"
}

data "aws_s3_bucket_object" "allowed-cidrs" {
  count  = length(data.aws_s3_bucket_objects.allowed-cidr-objects.keys)
  key    = element(data.aws_s3_bucket_objects.allowed-cidr-objects.keys, count.index)
  bucket = data.aws_s3_bucket_objects.allowed-cidr-objects.bucket
}

resource "aws_s3_bucket_object" "asg-tool-input" {
  bucket       = local.secrets_bucket_name
  content_type = "application/json"
  key          = "application-security-group-config.json"
  content = jsonencode({
    allowed = data.aws_s3_bucket_object.allowed-cidrs.*.body,
    blocked = data.aws_s3_bucket_object.blocked-cidrs.*.body,
  })
}

output "asg-config" {
  value = aws_s3_bucket_object.asg-tool-input.content
}

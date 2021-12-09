module "download-iaas-ca-certs" {
  source = "../../modules/download_certs"
  hosts  = var.iaas_trusted_ca_cert_hosts
}
variable "iaas_trusted_ca_cert_hosts" {
  type = list(string)
}

variable "secrets_bucket" {
  type = string
}

locals {
  iaas_trusted_ca_certs_s3_path                    = "iaas_trusted_ca_certs.pem"
}

resource "aws_s3_bucket_object" "iaas_trusted_ca_certs" {
  key          = local.iaas_trusted_ca_certs_s3_path
  bucket       = data.aws_s3_bucket.secrets.bucket
  content      = module.download-iaas-ca-certs.ca_certs
  content_type = "text/plain"
}

data "aws_s3_bucket" "secrets" {
  bucket = var.secrets_bucket
}
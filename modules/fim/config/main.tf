variable "secrets_bucket_name" {
}

variable "fim_config" {
}

data "template_file" "fim_template" {
  template = file("${path.module}/fim_config.tpl")
}

resource "aws_s3_bucket_object" "fim_template" {
  bucket  = var.secrets_bucket_name
  key     = var.fim_config
  content = data.template_file.fim_template.rendered
}

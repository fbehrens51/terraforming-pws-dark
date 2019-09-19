data "external" "presigned_url" {
  count = 1

  program = ["bash", "${path.module}/presign.sh"]

  query = {
    bucket_name = "${var.bucket_name}"
    object_key  = "${var.object_key}"
  }
}

variable "bucket_name" {}
variable "object_key" {}

output "value" {
  value = "${lookup(data.external.presigned_url.*.result[0], "url")}"
}

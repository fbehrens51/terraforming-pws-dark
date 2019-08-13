variable "env_name" {}

resource "random_string" "secret" {
  length = 64
}

data "external" "hmac" {
  count = 1

  program = ["bash", "${path.module}/hmac.sh"]

  query = {
    secret = "${random_string.secret.result}"
    string = "${var.env_name}"
  }
}

data "template_file" "keys" {
  count = 1

  template = "${lookup(data.external.hmac.*.result[count.index], "key")}"
}

output "value" {
  value     = "${element(concat(data.template_file.keys.*.rendered, list("")), 0)}"
  sensitive = true
}

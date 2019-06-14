variable "env_name" {}

resource "random_string" "secret" {
  length = 64
}

data "external" "hmac" {
  program = ["bash", "${path.module}/hmac.sh"]

  query = {
    secret = "${random_string.secret.result}"
    string = "${var.env_name}"
  }
}

//Using map type lookup to prevent error during plan
//see https://github.com/hashicorp/terraform/issues/17173
output "value" {
  value     = "${data.external.hmac.result["key"]}"
  sensitive = true
}

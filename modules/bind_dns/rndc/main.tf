variable "env_name" {
}

resource "random_string" "secret" {
  length = 64
}

data "external" "hmac" {
  count = 1

  program = ["bash", "${path.module}/hmac.sh"]

  query = {
    secret = random_string.secret.result
    string = var.env_name
  }
}

data "template_file" "keys" {
  count = 1

  template = data.external.hmac[count.index].result["key"]
}

output "value" {
  value     = data.template_file.keys[0].rendered
  sensitive = true
}


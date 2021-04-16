
variable "hosts" {
  type = list(string)
}

data "external" "download-cert" {
  program = ["go", "run", "${path.module}/main.go"]

  query = {
    hosts = join(",", var.hosts)
  }
}

output "ca_certs" {
  value = data.external.download-cert.result["certs"]
}

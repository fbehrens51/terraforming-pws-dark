
variable "hosts" {
  type = list(string)
}

data "external" "download-cert" {
  program = ["bash", "${path.module}/download-cert.sh"]

  query = {
    hosts = join(",", var.hosts)
  }
}

output "ca_certs" {
  value = data.external.download-cert.result["certs"]
}

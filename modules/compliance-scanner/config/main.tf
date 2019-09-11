variable "network_name" {}

variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}

variable "ntp_servers" {
  type = "list"
}

variable "syslog_host" {}
variable "syslog_port" {}

data "template_file" "compliance_scanner_config" {
  template = "${file("${path.module}/compliance_scanner_config.tpl")}"

  vars {
    network_name = "${var.network_name}"

    //availability_zones value isn't being used to configure AZs, so hard coding to use singleton_az for now
    //availability_zones = "[${join(",", var.availability_zones)}]"
    availability_zones = "${var.singleton_availability_zone}"

    singleton_availability_zone = "${var.singleton_availability_zone}"

    ntp_servers = "${join(",", var.ntp_servers)}"
    syslog_host = "${var.syslog_host}"
    syslog_port = "${var.syslog_port}"
  }
}

output "compliance_scanner_config" {
  value     = "${data.template_file.compliance_scanner_config.rendered}"
  sensitive = true
}

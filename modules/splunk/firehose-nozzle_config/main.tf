variable "api_endpoint" {}
variable "splunk_url" {}
variable "splunk_token" {}
variable "network_name" {}
variable "client_secret" {}

variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}

data "template_file" "firehose_config" {
  template = "${file("${path.module}/splunk_config.tpl")}"

  vars {
    api_endpoint = "${var.api_endpoint}"
    splunk_url   = "${var.splunk_url}"
    splunk_token = "${var.splunk_token}"
    network_name = "${var.network_name}"

    // availability_zones value isn't being used to configure AZs, so hard
    // coding to use singleton_az for now
    availability_zones = "${var.singleton_availability_zone}"

    client_secret = "${var.client_secret}"

    singleton_availability_zone = "${var.singleton_availability_zone}"
  }
}

output "firehose_config" {
  value     = "${data.template_file.firehose_config.rendered}"
  sensitive = true
}

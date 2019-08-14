variable "om_url" {}
variable "network_name" {}
variable "env_name" {}

variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}
variable "health_check_availability_zone" {}

data "template_file" "hw_vpc_azs" {
  count = "${length(var.availability_zones)}"

  template = <<EOF
- name: $${hw_subnet_availability_zone}
EOF

  vars = {
    hw_subnet_availability_zone = "${var.availability_zones[count.index]}"
  }
}

data "template_file" "healthwatch_config" {
  template = "${file("${path.module}/healthwatch_config.tpl")}"

  vars {
    foundation_name = "${var.env_name}"
    om_url          = "${var.om_url}"
    network_name    = "${var.network_name}"

    //availability_zones value isn't being used to configure AZs, so hard coding to use singleton_az for now
    //    availability_zones = "[${join(",", var.availability_zones)}]"
    hw_vpc_azs = "${indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))}"

    //    availability_zones = "${var.singleton_availability_zone}"
    //
    singleton_availability_zone = "${var.singleton_availability_zone}"

    health_check_availability_zone = "${var.health_check_availability_zone}"
    env_name                       = "${var.env_name}"
  }
}

output "healthwatch_config" {
  value = "${data.template_file.healthwatch_config.rendered}"
}
variable "cidr_block" {}
variable "vpc_id" {}

variable "availability_zones" {
  type = "list"
}

variable "tags" {
  type = "map"
}

locals {
  newbits = "${ceil(log(length(var.availability_zones), 2))}"
}

resource "aws_subnet" "subnet" {
  count      = "${length(var.availability_zones)}"
  cidr_block = "${cidrsubnet(var.cidr_block,local.newbits,count.index)}"
  vpc_id     = "${var.vpc_id}"

  availability_zone = "${var.availability_zones[count.index]}"

  tags = "${var.tags}"
}

output "subnet_ids" {
  value = "${aws_subnet.subnet.*.id}"
}

output "subnet_cidr_blocks" {
  value = "${aws_subnet.subnet.*.cidr_block}"
}

data "template_file" "gateways" {
  count = "${length(var.availability_zones)}"

  template = <<EOF
${cidrhost(aws_subnet.subnet.*.cidr_block[count.index], 1)}
EOF
}

output "subnet_gateways" {
  value = "${data.template_file.gateways.*.rendered}"
}

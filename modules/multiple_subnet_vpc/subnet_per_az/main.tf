variable "cidr_block" {}
variable "vpc_id" {}

variable "availablity_zones" {
  type = "list"
}

variable "newbits" {}

variable "tags" {
  type = "map"
}

resource "aws_subnet" "subnet" {
  count      = "${length(var.availablity_zones)}"
  cidr_block = "${cidrsubnet(var.cidr_block,var.newbits,count.index)}"
  vpc_id     = "${var.vpc_id}"

  tags = "${var.tags}"
}

output "subnet_ids" {
  value = "${aws_subnet.subnet.*.id}"
}

output "subnet_cidr_blocks" {
  value = "${aws_subnet.subnet.*.cidr_block}"
}

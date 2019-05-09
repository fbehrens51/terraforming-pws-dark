variable "eni_security_groups" {
  type = "list"
}

variable "tags" {
  type = "map"
  default = {}
}
variable "eni_subnet_id" {}

resource "aws_network_interface" "eni" {
  subnet_id = "${var.eni_subnet_id}"
  security_groups = [
    "${var.eni_security_groups}"]

  tags = "${var.tags}"
}

output "eni_id" {
  value = "${aws_network_interface.eni.id}"
}

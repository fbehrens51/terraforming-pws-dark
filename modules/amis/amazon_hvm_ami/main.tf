variable "region" {
  description = "Region to retrieve AMI for"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_ami" "amazon_linux_hvm_ami" {
  most_recent = true

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm*",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  filter {
    name = "root-device-type"

    values = [
      "ebs",
    ]
  }
}

output "id" {
  value = "${data.aws_ami.amazon_linux_hvm_ami.id}"
}

output "name" {
  value = "${data.aws_ami.amazon_linux_hvm_ami.name}"
}

output "tags" {
  value = "${data.aws_ami.amazon_linux_hvm_ami.tags}"
}

variable "region" {}

provider "aws" {
  region = "${var.region}"
}

variable "ami" {
  type = "string"
}

variable "subnet_id" {
  type = "string"
}

variable "security_group_ids" {
  type        = "list"
  description = "List of security groups to allow ssh to importer"
}

variable "enable_public_ip" {
  description = "Required if running from outside of VPC"
  default     = false
}

variable "instance_role" {
  default     = ""
  description = "instance profile name with necessary privileges"
}

variable "instance_type" {
  description = "How much muscle does it need to extract the tgz and then dd to a volume?"
}

data "aws_subnet" "vm_subnet" {
  id = "${var.subnet_id}"
}

data "aws_ebs_volume" "vm_importer_volume" {
  most_recent = true

  filter {
    name = "attachment.instance-id"

    values = [
      "${aws_instance.vm_importer.id}",
    ]
  }

  filter {
    name = "attachment.device"

    values = [
      "/dev/xvdf",
    ]
  }
}

module "key_pair" {
  source = "../key_pair"
  key_name = "vm importer"
}

resource "aws_instance" "vm_importer" {
  availability_zone = "${data.aws_subnet.vm_subnet.availability_zone}"
  ami               = "${var.ami}"
  instance_type     = "${var.instance_type}"
  key_name          = "${module.key_pair.key_name}"

  vpc_security_group_ids = [
    "${var.security_group_ids}",
  ]

  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = "${var.enable_public_ip}"
  iam_instance_profile        = "${var.instance_role}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 64
  }

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp2"
    volume_size = 64
  }

  tags = "${map("Name", "vm_importer")}"
}

output "vm_importer_private_key" {
  value = "${module.key_pair.private_key_pem}"
}

output "vm_importer_volume_id" {
  value = "${data.aws_ebs_volume.vm_importer_volume.id}"
}

output "vm_importer_host" {
  value = "${aws_instance.vm_importer.public_dns}"
}

output "vm_importer_private_ip" {
  value = "${aws_instance.vm_importer.private_ip}"
}

output "vm_importer_public_ip" {
  value = "${aws_instance.vm_importer.public_ip}"
}

output "vm_importer_instance_id" {
  value = "${aws_instance.vm_importer.id}"
}

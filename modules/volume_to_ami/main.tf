variable "region" {
}

provider "aws" {
  region = "${var.region}"
}

variable "volume_id" {
  type = "string"
}

variable "is_linux" {
  default = true
}

variable "ami_name" {
  type = "string"
}

locals {
  snapshot_tag_name="MJB_AMI_SNAPSHOT-${timestamp()}"
}


module "snapshot" {
  source = "../ebs_snapshot"
  volume_id = "${var.volume_id}"
  is_linux = "${var.is_linux}"
  triggers = "${local.snapshot_tag_name}"
  name_tag = "${local.snapshot_tag_name}"
}

//Are we going to have a problem with timing/eventual consistency?
data "aws_ebs_snapshot" "vm_snapshot" {

  filter {
    name   = "tag:Name"
    values = ["${local.snapshot_tag_name}"]
  }
  depends_on = ["module.snapshot"]
}

resource "aws_ami" "vm_ami" {
  name = "${var.ami_name}"
  virtualization_type = "hvm"
  root_device_name = "/dev/xvda"

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "${data.aws_ebs_snapshot.vm_snapshot.id}"
    volume_size = 64
  }
  //TODO: identify naming/tagging convention typically used by Pivotal and apply here
  //Makes it easier to filter (using Name tag)
    tags {
      Name="MJB_AMI"
    }
}

output "ami_id" {
  value = "${aws_ami.vm_ami.id}"
}

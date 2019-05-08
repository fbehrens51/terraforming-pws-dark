variable "region" {
}

provider "aws" {
  region = "${var.region}"
}

variable "volume_id" {
  type = "string"
}

variable "ami_name" {
  type = "string"
}

resource "aws_ebs_snapshot" "vm_snapshot" {
  volume_id = "${var.volume_id}"

  tags {
    Name = "MJB_AMI_SNAPSHOT"
  }
}

resource "aws_ami" "vm_ami" {
  name = "${var.ami_name}"
  virtualization_type = "hvm"
  root_device_name = "/dev/xvda"

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "${aws_ebs_snapshot.vm_snapshot.id}"
    volume_size = 150
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

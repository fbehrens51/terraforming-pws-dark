variable "kms_key_id" {}

data "aws_ami" "current_ami" {
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_ebs_volume" "encrypted_volume" {
  availability_zone = "${data.aws_availability_zones.azs.names[0]}"
  encrypted = true
  kms_key_id = "${var.kms_key_id}"
  snapshot_id = "${data.aws_ami.current_ami.root_snapshot_id}"
}

resource "aws_ebs_snapshot" "encrypted_snapshot" {
  volume_id = "${aws_ebs_volume.encrypted_volume.id}"
}

resource "aws_ami" "encrypted_ami" {
  name = "encrypted_${data.aws_ami.current_ami.name}"
  virtualization_type = "${data.aws_ami.current_ami.virtualization_type}"
  root_device_name    = "/dev/xvda"

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "${aws_ebs_snapshot.encrypted_snapshot.id}"
    volume_size = "${aws_ebs_volume.encrypted_volume.size}"
  }
}
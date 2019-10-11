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

module "create_ami" {
  source = "../../create_ami_from_volume"
  volume_id ="${aws_ebs_volume.encrypted_volume.id}"
  name_prefix = "encrypted_${data.aws_ami.current_ami.name}"
  depends_on = ["${aws_ebs_volume.encrypted_volume.arn}"]
}

variable "kms_key_id" {}

data "aws_ami" "current_ami" {
  most_recent = true

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }

  name_regex = "^amzn2-ami-hvm-[0-9.]+-x86_64-ebs$"

  owners = []
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

resource "null_resource" "create_snapshot_and_ami" {
  provisioner "local-exec" {
    command = "bash ${path.module}/create_snapshot.sh ${aws_ebs_volume.encrypted_volume.id} encrypted_${data.aws_ami.current_ami.name}"
  }
  depends_on = ["aws_ebs_volume.encrypted_volume"]
}

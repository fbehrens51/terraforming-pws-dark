variable "kms_key_id" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "current_ami" {
  most_recent = true
  name_regex = "^pivotal-ops-manager-v2.5.[0-9]*-build.[0-9]*$"
  owners = ["${data.aws_caller_identity.current.account_id}"]
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

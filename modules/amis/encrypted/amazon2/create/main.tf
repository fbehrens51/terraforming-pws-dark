variable "kms_key_id" {}

data "aws_ami" "current_ami" {
  most_recent = true

  name_regex = "^amzn2-ami-hvm-[0-9.]+-x86_64-ebs$"

  owners = ["amazon"]
}

data "aws_region" "current_region" {}

resource "aws_ami_copy" "encrypted_amazon2_ami" {
  name              = "encrypted_${data.aws_ami.current_ami.name}"
  source_ami_id     = "${data.aws_ami.current_ami.id}"
  source_ami_region = "${data.aws_region.current_region.name}"
  encrypted         = true
  kms_key_id        = "${var.kms_key_id}"
}

output "encrypted_ami_id" {
  value = "${aws_ami_copy.encrypted_amazon2_ami.id}"
}

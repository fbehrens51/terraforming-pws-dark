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

data "aws_region" "current_region" {
  current = true
}

resource "random_integer" "name_extension" {
  max = 999999999
  min = 0
}
resource "aws_ami_copy" "encrypted_amazon2_ami" {
  name = "encrypted_${data.aws_ami.current_ami.name}-${random_integer.name_extension.result}"
  source_ami_id = "${data.aws_ami.current_ami.id}"
  source_ami_region = "${data.aws_region.current_region.name}"
  encrypted = true
  kms_key_id = "${var.kms_key_id}"
}
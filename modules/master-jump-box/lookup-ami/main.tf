data "aws_caller_identity" "self" {}

data "aws_ami" "mjb_ami" {
  most_recent = true
  owners      = ["${data.aws_caller_identity.self.account_id}"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:Name"
    values = ["MJB_AMI"]
  }
}

output "id" {
  value = "${data.aws_ami.mjb_ami.id}"
}

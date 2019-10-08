data "aws_caller_identity" "current" {}

data "aws_ami" "current_ami" {
  filter {
    name   = "name"
    values = ["encrypted_amzn-ami-vpc-nat*"]
  }

  most_recent = true
  owners      = ["${data.aws_caller_identity.current.account_id}"]
}

output "id" {
  value = "${data.aws_ami.current_ami.id}"
}
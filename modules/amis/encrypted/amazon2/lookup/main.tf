data "aws_caller_identity" "current" {}

data "aws_ami" "current_ami" {
  most_recent = true

//  filter {
//    name = "owner-alias"
//
//    values = [
//      "${data.aws_caller_identity.current.account_id}",
//    ]
//  }

  name_regex = "^encrypted_amzn2-ami-hvm-[0-9.]+-x86_64-ebs$"

  owners = ["${data.aws_caller_identity.current.account_id}"]
}

output "id" {
  value = "${data.aws_ami.current_ami.id}"
}
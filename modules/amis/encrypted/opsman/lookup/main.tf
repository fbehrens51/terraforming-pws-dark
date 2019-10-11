data "aws_caller_identity" "current" {}

data "aws_ami" "current_ami" {
  most_recent = true
  name_regex = "search : ^encrypted_pivotal-ops-manager-v2.5.[0-9]*-build.[0-9]*-[0-9]*$"
  owners = ["${data.aws_caller_identity.current.account_id}"]
}

output "id" {
  value = "${data.aws_ami.current_ami.id}"
}
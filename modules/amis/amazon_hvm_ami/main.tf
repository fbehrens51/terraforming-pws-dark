data "aws_ami" "amazon_linux_hvm_ami" {
  most_recent = true

  name_regex = "^amzn2-ami-hvm-[0-9.]+-x86_64-ebs$"

  owners = ["amazon"]
}

output "id" {
  value = data.aws_ami.amazon_linux_hvm_ami.id
}

output "name" {
  value = data.aws_ami.amazon_linux_hvm_ami.name
}

output "tags" {
  value = data.aws_ami.amazon_linux_hvm_ami.tags
}


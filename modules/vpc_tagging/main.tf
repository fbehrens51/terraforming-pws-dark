variable "vpc_id" {
  type = string
}

variable "env_name" {
  type = string
}

variable "name" {
  type = string
}

variable "purpose" {
  type = string
}

resource "null_resource" "vpc_tags" {
  triggers = {
    vpc_id   = var.vpc_id
    name     = "${var.env_name} | ${var.name} vpc"
    env_name = var.env_name
    purpose  = var.purpose
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${self.triggers.vpc_id} --tags 'Key=Name,Value=${self.triggers.name}' 'Key=Purpose,Value=${self.triggers.purpose}' 'Key=env_name,Value=${self.triggers.env_name}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 delete-tags --resources ${self.triggers.vpc_id} --tags 'Key=Name,Value=${self.triggers.name}' 'Key=Purpose,Value=${self.triggers.purpose}' 'Key=env_name,Value=${self.triggers.env_name}'"
  }
}
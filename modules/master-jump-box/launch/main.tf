variable "ami_id" {
  description = "id for AMI"
}
variable "instance_type" {
  description = "Instance Type to use for Master Jump Box"
}

variable "subnet_id" {
  description = "subnet to launch MJB in"
}

variable "enable_public_ip" {
  default = true
  description = "enable a public IP on the MJB"
}

variable "instance_profile" {
  description = "Instance Profile to assign to MJB"
}

variable "key_name" {}

variable "security_group_id" {
  description = "security group to apply to MJB"
}

variable "user_data_yml" {
  description = "Full path to user data file to set up the instance"
}

data "aws_security_group" "security_group" {
  id = "${var.security_group_id}"
}

resource "aws_instance" "mjb" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_id}"
  user_data = "${data.template_cloudinit_config.user_data.rendered}"
  associate_public_ip_address = "${var.enable_public_ip}"
  iam_instance_profile = "${var.instance_profile}"
  vpc_security_group_ids = ["${data.aws_security_group.security_group.*.id}"]
  key_name = "${var.key_name}"
  tags {
    Name="MJB-${timestamp()}"
  }
}

locals {
  //hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  local_user_data_path =  "${replace(var.user_data_yml, "\\", "/")}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip = false
  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
runcmd:
  - sudo touch /cloud-init-is-working.txt
EOF
  }

  # Main cloud-config configuration file.
  part {
    filename     = "user_data.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${local.local_user_data_path}")}"
  }
}

output "instance_id" {
  value = "${aws_instance.mjb.id}"
}

output "private_ip" {
  value = "${aws_instance.mjb.private_ip}"
}

output "public_ip" {
  value = "${aws_instance.mjb.public_ip}"
}

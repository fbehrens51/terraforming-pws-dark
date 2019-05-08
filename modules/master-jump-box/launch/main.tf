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

variable "security_group_id" {
  description = "security group to apply to MJB"
}

variable "key_pair" {
  description = "key pair to use for mjb instance"
  default = ""
}

variable "users_yml" {
  description = "Full path to user data file to set up the users"
}

variable "trusted_cas_yml" {
  description = "Full path to user data file to set up the cas"
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
  security_groups = ["${data.aws_security_group.security_group.*.id}"]
  key_name = "${var.key_pair}"
  tags {
    Name="MJB-${timestamp()}"
  }
}

locals {
//hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  local_users_path =  "${replace(var.users_yml, "\\", "/")}"
  local_ca_path =  "${replace(var.trusted_cas_yml, "\\", "/")}"
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
    filename     = "user.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${local.local_users_path}")}"
  }

  # Main cloud-config configuration file.
  part {
    filename     = "ca.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${local.local_ca_path}")}"
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

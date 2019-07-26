data "aws_ami" "ubuntu_hvm_ami" {
  most_recent = true

  filter {
    name = "owner-id"

    values = [
      "099720109477",
    ] # Canonical
  }

  filter {
    name = "name"

    values = [
      "ubuntu*18.04*",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  filter {
    name = "architecture"

    values = [
      "x86_64",
    ]
  }

  filter {
    name = "root-device-type"

    values = [
      "ebs",
    ]
  }
}

output "id" {
  value = "${data.aws_ami.ubuntu_hvm_ami.id}"
}

output "name" {
  value = "${data.aws_ami.ubuntu_hvm_ami.name}"
}

output "tags" {
  value = "${data.aws_ami.ubuntu_hvm_ami.tags}"
}

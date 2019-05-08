//TODO:modify to output snapshot-id
variable "is_linux" {
  default = true
}

variable "volume_id" {}

variable "triggers" {
  default = ""
}

locals {
  windows_run = "${var.is_linux ? 0 : 1}"
  linux_run = "${var.is_linux ? 1 : 0}"
}

resource "null_resource" "create_initial_snapshot_w" {
  count = "${local.windows_run}"
  provisioner "local-exec" {
    command = "echo ${local.linux_run}}"
  }
  provisioner "local-exec" {
    command = "aws ec2 create-snapshot --volume ${var.volume_id}"
  }
  triggers {
    file_id = "${var.triggers}"
  }
}


resource "null_resource" "create_initial_snapshot_l" {
  count = "${local.linux_run}"

  provisioner "local-exec" {
    command = "echo ${local.linux_run}}"
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/create-snapshot.sh ${var.volume_id}"
  }

  triggers {
    file_id = "${var.triggers}"
  }
}
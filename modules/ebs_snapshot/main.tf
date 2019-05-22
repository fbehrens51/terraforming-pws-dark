//TODO:modify to output snapshot-id
variable "is_linux" {
  default = true
}

variable "volume_id" {}

variable "triggers" {
  default = ""
}

variable "name_tag" {
  default = ""
}

locals {
  windows_run           = "${var.is_linux ? 0 : 1}"
  linux_run             = "${var.is_linux ? 1 : 0}"
  snapshot_default_name = "SNAPSHOT-${timestamp()}"
  tag                   = "${ length(var.name_tag)>0 ? var.name_tag : local.snapshot_default_name}"
}

resource "aws_ebs_snapshot" "windows_snapshot" {
  count     = "${local.windows_run}"
  volume_id = "${var.volume_id}"

  tags {
    Name = "${var.name_tag}"
  }
}

resource "null_resource" "create_initial_snapshot_l" {
  count = "${local.linux_run}"

  provisioner "local-exec" {
    command = "echo ${local.linux_run}}"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/create-snapshot.sh ${var.volume_id} '${local.tag}'"
  }

  triggers {
    file_id = "${var.triggers}"
  }
}

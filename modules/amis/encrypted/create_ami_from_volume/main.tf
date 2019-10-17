variable "volume_id" {}
variable "name_prefix" {}

variable depends_on {
  default = []

  type = "list"
}

resource "null_resource" "depends_on" {
  triggers {
    depends_on = "${join("", var.depends_on)}"
  }
}

resource "null_resource" "create_snapshot_and_ami" {
  triggers = {
    volume_id = "${var.volume_id}"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/create_snapshot.sh ${var.volume_id} ${var.name_prefix}"
  }

  depends_on = ["null_resource.depends_on"]
}

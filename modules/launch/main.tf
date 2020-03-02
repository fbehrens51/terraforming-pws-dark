//TODO: terraform thinks the user_data is changing when running on different machines.  Need to research
variable "ami_id" {
  description = "ami ID to use to launch instance"
}

variable "instance_type" {
  default = "t2.small"
}

variable "user_data" {
  description = "user data"
}

variable "eni_ids" {
  type = list(string)
}

variable "iam_instance_profile" {
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "ignore_tag_changes" {
  default = false
  type    = bool
}

//allows calling module to set a fixed count since count cannot use a value calculated from something that may not exist yet (e.g. eni_ids)
variable "instance_count" {
  default = 1
}

locals {
  computed_instance_tags = {
    SourceAmiId = var.ami_id
  }
}

variable "root_block_device" {
  type    = map(string)
  default = {}
}

resource "aws_instance" "instance" {
  count = var.ignore_tag_changes ? 0 : var.instance_count

  network_interface {
    device_index         = 0
    network_interface_id = var.eni_ids[count.index]
  }

  ami                  = var.ami_id
  instance_type        = var.instance_type
  user_data            = var.user_data
  iam_instance_profile = var.iam_instance_profile

  tags = merge(var.tags, local.computed_instance_tags)
  dynamic "root_block_device" {
    for_each = [var.root_block_device]
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }
}

resource "aws_instance" "instance_ignoring_tags" {
  count = var.ignore_tag_changes ? var.instance_count : 0

  network_interface {
    device_index         = 0
    network_interface_id = var.eni_ids[count.index]
  }

  ami                  = var.ami_id
  instance_type        = var.instance_type
  user_data            = var.user_data
  iam_instance_profile = var.iam_instance_profile

  tags = merge(var.tags, local.computed_instance_tags)
  dynamic "root_block_device" {
    for_each = [var.root_block_device]
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  lifecycle {
    // We don't want terraform to remove tags applied later by customer processes
    ignore_changes = [tags]
  }
}

output "instance_ids" {
  value = concat(aws_instance.instance.*.id, aws_instance.instance_ignoring_tags.*.id)
}

output "private_ips" {
  value = concat(aws_instance.instance.*.private_ip, aws_instance.instance_ignoring_tags.*.private_ip)
}


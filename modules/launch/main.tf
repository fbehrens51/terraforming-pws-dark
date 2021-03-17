//TODO: terraform thinks the user_data is changing when running on different machines.  Need to research
variable "ami_id" {
  description = "ami ID to use to launch instance"
}

variable "instance_types" {
  type        = map(map(string))
  description = "output from the scaling-params layer"
}

variable "scale_vpc_key" {
  description = "key from the scaling-params layer which indicates the VPC (e.g. control-plane)"
}

variable "scale_service_key" {
  description = "key from the scaling-params layer which indicates the service name (e.g. nat)"
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

variable "ssh_timeout" {
  default = "10m"
}

variable "bot_user" {
  default = "bot"
}

variable "check_cloud_init" {
  description = "Wait for cloud-init to complete. Set to false for hosts that have volume_attachments, or do not have the bot user installed"
  default     = true
}

variable "bot_key_pem" {
  default = null
}

variable "bastion_host" {
  default = null
}

variable "volume_ids" {
  type    = list(string)
  default = null
}

variable "device_name" {
  default = "/dev/sdf"
}

//allows calling module to set a fixed count since count cannot use a value calculated from something that may not exist yet (e.g. eni_ids)
variable "instance_count" {
  default = 1
}

locals {
  instance_type = var.instance_types[var.scale_vpc_key][var.scale_service_key]
  computed_instance_tags = {
    SourceAmiId = var.ami_id
  }
}

variable "root_block_device" {
  type    = map(string)
  default = {}
}

// pas_nats, enterprise_nats, iso_seg_nats, postfix, bind, ldap, ops-manager, control-plane-ops-manager

resource "aws_instance" "instance" {
  count = var.ignore_tag_changes == false && var.check_cloud_init == true ? var.instance_count : 0

  network_interface {
    device_index         = 0
    network_interface_id = var.eni_ids[count.index]
  }

  ami                  = var.ami_id
  instance_type        = local.instance_type
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
    ignore_changes = [tags["operating-system"], tags["cloud_init_done"]]
  }
  provisioner "local-exec" {
    command = <<-EOF
    #!/usr/bin/env bash
    set -ex
    completed_tag="cloud_init_done"
    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${self.id} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
    echo "running $poll_tags"
    tags="$($poll_tags)"
    COUNTER=0
    LOOP_LIMIT=30
    while [[ "$tags" == "" ]] ; do
      if [[ $COUNTER -eq $LOOP_LIMIT ]]; then
        echo "timed out waiting for $completed_tag to be set"
        exit 1
      fi
      if [[ $COUNTER -gt 0 ]]; then
        echo "$completed_tag not set, sleeping for 10s"
        sleep 10s
      fi
      tags="$($poll_tags)"
      let COUNTER=COUNTER+1
    done
    echo "$completed_tag = $tags"
    EOF
  }
}

// fluentd VMs, control_plane_nats, SJB (last two allow bootstraping an environment).
resource "aws_instance" "unchecked_instance" {
  count = var.ignore_tag_changes == false && var.check_cloud_init == false ? var.instance_count : 0

  network_interface {
    device_index         = 0
    network_interface_id = var.eni_ids[count.index]
  }

  ami                  = var.ami_id
  instance_type        = local.instance_type
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
    ignore_changes = [tags["operating-system"]]
  }
}

resource "aws_volume_attachment" "volume_attachment" {
  count        = var.volume_ids == null ? 0 : length(var.volume_ids)
  skip_destroy = true
  instance_id  = element(aws_instance.unchecked_instance.*.id, count.index)
  volume_id    = element(var.volume_ids, count.index)
  device_name  = var.device_name
}

// Bastion instance
resource "aws_instance" "instance_ignoring_tags" {
  count = var.ignore_tag_changes ? var.instance_count : 0

  network_interface {
    device_index         = 0
    network_interface_id = var.eni_ids[count.index]
  }

  ami                  = var.ami_id
  instance_type        = local.instance_type
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
  value = concat(aws_instance.instance.*.id, aws_instance.unchecked_instance.*.id, aws_instance.instance_ignoring_tags.*.id)
}

output "private_ips" {
  value = concat(aws_instance.instance.*.private_ip, aws_instance.unchecked_instance.*.private_ip, aws_instance.instance_ignoring_tags.*.private_ip)
}


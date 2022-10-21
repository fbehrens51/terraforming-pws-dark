terraform {
  experiments = [module_variable_optional_attrs]
}

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

variable "iam_instance_profile" {
  default = ""
}

variable "tags" {
  type = map(string)
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

variable "cloud_init_timeout" {
  type    = number
  default = 300
}

variable "module_instance_count" {
  type        = number
  default     = 9999
  description = "This is required when the module + count is used"
}

variable "iso_seg_name" {
  type        = string
  default     = null
  description = "Used to name the nats <env>_isolation_segment_<iso_seg_name>_nat_<index>"
}

variable "operating_system" {
  type        = string
  default     = ""
  description = "Default value for OS tag, defaults to empty string becuase module is called from ldap layer"
}

//allows calling module to set a fixed count since count cannot use a value calculated from something that may not exist yet (e.g. eni_ids)
variable "instance_count" {
  default = 1
}

locals {
  instance_type = var.instance_types[var.scale_vpc_key][var.scale_service_key]
  computed_instance_tags = {
    SourceAmiId      = var.ami_id
    operating-system = var.operating_system
  }
  iso_nat_name = var.scale_vpc_key == "isolation-segment" ? "${replace(var.scale_vpc_key, "-", "_")}_${lower(replace(var.iso_seg_name, "/[ -]/", "_"))}" : "${replace(var.scale_vpc_key, "-", "_")}"
  om_name = (var.scale_service_key != "ops-manager" ? "" :
    var.scale_vpc_key == "pas" ? "om" : "cp_om"
  )
  key = (
    var.scale_service_key == "nat" ? "${local.iso_nat_name}_${var.scale_service_key}" :
    var.scale_service_key == "ops-manager" ? local.om_name :
    var.scale_service_key
  )
  ssh_host_names = (
    var.module_instance_count != 9999 ? formatlist("%s_%s_%d", var.tags["foundation_name"], local.key, [var.module_instance_count + 1]) :
    var.instance_count != 1 ? formatlist("%s_%s_%d", var.tags["foundation_name"], local.key, range(1, var.instance_count + 1)) :
    formatlist("%s_%s", var.tags["foundation_name"], local.key)
  )
}

variable "root_block_device" {
  type = object({
    delete_on_termination = optional(string)
    encrypted             = optional(string)
    iops                  = optional(string)
    tags                  = optional(map(string))
    kms_key_id            = optional(string)
    volume_size           = optional(string)
    volume_type           = optional(string)
  })
  default = {}
}

variable "availability_zone" {
  default = null
}

variable "create_before_destroy" {
  type    = bool
  default = false
}

variable "internetless" {
  type = bool
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "source_dest_check" {
  type    = bool
  default = false
}

// pas_nats, enterprise_nats, iso_seg_nats

resource "aws_instance" "cbd_instance" {
  count = var.instance_count

  associate_public_ip_address = !var.internetless

  ami                    = var.ami_id
  instance_type          = local.instance_type
  user_data              = var.user_data
  iam_instance_profile   = var.iam_instance_profile
  subnet_id              = var.subnet_ids[count.index]
  vpc_security_group_ids = var.security_group_ids
  source_dest_check      = var.source_dest_check

  tags = merge(var.tags, local.computed_instance_tags, { "ssh_host_name" = local.ssh_host_names[count.index] })
  dynamic "root_block_device" {
    for_each = [var.root_block_device]
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      tags                  = lookup(root_block_device.value, "tags", {})
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
    #!/usr/bin/env bash
    set -e
    completed_tag="cloud_init_done"
    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${self.id} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
    echo "running $poll_tags"
    tags="$($poll_tags)"
    COUNTER=0
    LOOP_LIMIT=${var.cloud_init_timeout / 10}
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

    if cloud_init_message="$( aws ec2 describe-tags --filters Name=resource-id,Values=${self.id} Name=key,Values=cloud_init_output --output text --query Tags[*].Value )"; then
      [[ ! -z $cloud_init_message ]] && echo -e "cloud_init_output: $( echo -ne "$cloud_init_message" | openssl enc -d -a | gunzip -qc - )"
    fi

    [[ $tags == false ]] && exit 1 || exit 0
    EOF
  }

}


output "instance_ids" {
  value = aws_instance.cbd_instance.*.id
}

output "private_ips" {
  value = aws_instance.cbd_instance.*.private_ip
}

output "ssh_host_names" {
  value = flatten(local.ssh_host_names)
}

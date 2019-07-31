provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "pas"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  vpc_id                      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  director_role_name          = "${data.terraform_remote_state.paperwork.director_role_name}"
  om_security_group_id        = "${data.terraform_remote_state.pas.om_security_group_id}"
  om_ssh_public_key_pair_name = "${data.terraform_remote_state.pas.om_ssh_public_key_pair_name}"
  om_elb_id                   = "${data.terraform_remote_state.pas.om_elb_id}"
  om_eip_allocation_id        = "${data.terraform_remote_state.pas.om_eip_allocation_id}"
  om_eni_id                   = "${data.terraform_remote_state.pas.om_eni_id}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-ops-manager"))}"
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}

variable "om_ami_id" {}

variable "env_name" {}

variable "tags" {
  type = "map"
}

variable "user_data_path" {}

variable "instance_type" {}

module "ops_manager" {
  instance_count = "1"

  source               = "../../modules/launch"
  ami_id               = "${var.om_ami_id}"
  iam_instance_profile = "${local.director_role_name}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.om_ssh_public_key_pair_name}"
  tags                 = "${local.tags}"
  eni_ids              = ["${local.om_eni_id}"]
  user_data            = "${data.template_cloudinit_config.config.rendered}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 150
  }
}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
  }

  part {
    content_type = "text/cloud-config"

    content = <<CLOUDINIT
bootcmd:
  # Disable SSL in postgres.  Otherwise, postgres will fail to start since the
  # snakeoil certificate is missing.  Note that OM connect to postgres over the
  # unix socket.
  - sudo sed -i 's/^ssl = true/#ssl = true/' /etc/postgresql/*/main/postgresql.conf
CLOUDINIT
  }
}

resource "aws_elb_attachment" "opsman_attach" {
  elb      = "${local.om_elb_id}"
  instance = "${module.ops_manager.instance_ids[0]}"
}

resource "aws_eip_association" "om_eip_assoc" {
  count         = "${length(local.om_eip_allocation_id)>0 ? 1 : 0}"
  instance_id   = "${module.ops_manager.instance_ids[0]}"
  allocation_id = "${local.om_eip_allocation_id}"
}

output "ops_manager_private_ip" {
  value = "${module.ops_manager.private_ips[0]}"
}

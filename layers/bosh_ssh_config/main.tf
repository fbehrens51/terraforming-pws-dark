variable "remote_state_region" {
}

variable "remote_state_bucket" {
}


data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

variable "host_ip" {
  type = string
}

variable "ssh_key_pem" {

}
variable "ssh_name_prefix" {
  type = string
  default = ""
}

locals{
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  ssh_key_name = (var.ssh_name_prefix == "" ? "${data.terraform_remote_state.paperwork.outputs.foundation_name}_bbr_key.pem" : "${data.terraform_remote_state.paperwork.outputs.foundation_name}_${var.ssh_name_prefix}_bbr_key.pem")
  proxy_name   = (var.ssh_name_prefix == "" ? "${data.terraform_remote_state.paperwork.outputs.foundation_name}_om" : "${data.terraform_remote_state.paperwork.outputs.foundation_name}_${var.ssh_name_prefix}_om")
  host_type = (var.ssh_name_prefix == "" ? "bosh_director" : "${var.ssh_name_prefix}_bosh_director")
  host_name = (var.ssh_name_prefix == "" ? "${data.terraform_remote_state.paperwork.outputs.foundation_name}_bosh" : "${data.terraform_remote_state.paperwork.outputs.foundation_name}_${var.ssh_name_prefix}_bosh")
}

module "sshconfig" {
  source         = "../../modules/ssh_config"
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips = zipmap(flatten([local.host_name]), [var.host_ip])
  host_type = local.host_type
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  custom_inner_proxy = local.proxy_name
  ssh_user = "bbr"
  custom_ssh_key = local.ssh_key_name
}

resource "aws_s3_bucket_object" "bbr_key" {
  bucket       = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  key          = "sshconfig/${local.ssh_key_name}"
  content      = var.ssh_key_pem
  content_type = "text/plain"
}
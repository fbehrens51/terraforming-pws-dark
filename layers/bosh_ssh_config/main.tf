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

variable "host_name" {
  type = string
}


variable "ssh_key_pem" {

}
variable "ssh_name_prefix" {
  type = string
  default = ""
}

locals{
  ssh_key_name = (var.ssh_name_prefix == "" ? "sshconfig/${data.terraform_remote_state.paperwork.outputs.foundation_name}_bbr_key.pem" : "sshconfig/${data.terraform_remote_state.paperwork.outputs.foundation_name}_${var.ssh_name_prefix}_bbr_key.pem")
  proxy_name   = (var.ssh_name_prefix == "" ? "om" : "${var.ssh_name_prefix}_om")
}

module "sshconfig" {
  source         = "../../modules/ssh_config"
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips = zipmap(flatten([var.host_name]), [var.host_ip])
  host_type = "bosh_director"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  custom_inner_proxy = local.proxy_name
  ssh_user = "bbr"
}



resource "aws_s3_bucket_object" "bbr_key" {
  bucket       = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  key          = local.ssh_key_name
  content      = var.ssh_key_pem
  content_type = "text/plain"
}
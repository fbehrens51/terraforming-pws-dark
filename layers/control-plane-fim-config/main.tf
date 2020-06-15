variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "fim_config" {
  default = "control_plane/fim_addon_config.yml"
}

terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
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

module "fim_config" {
  source              = "../../modules/fim/config"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  fim_config          = var.fim_config
}

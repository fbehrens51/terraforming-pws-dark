variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "fim_config" {
  default = "pas/fim_addon_tile_config.yml"
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

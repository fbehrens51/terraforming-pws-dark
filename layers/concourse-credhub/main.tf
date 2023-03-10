data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane_foundation" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane_foundation"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "ops-manager" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "ops-manager"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "control-plane-ops-manager" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "control-plane-ops-manager"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}



variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

data "aws_caller_identity" "current" {
}


module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}


locals {
  credhub_vars_key = "concourse/generated-credhub-vars.yml"

  credhub_vars = templatefile("${path.module}/credhub_vars.tpl", {
    ACCOUNT_ID         = data.aws_caller_identity.current.account_id
    BOT_KEY_PEM        = data.terraform_remote_state.paperwork.outputs.bot_private_key
    CA_CERT_BUCKET     = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
    CP_OM_PRIVATE_IP   = data.terraform_remote_state.control-plane-ops-manager.outputs.ops_manager_private_ip
    ENV_NAME           = data.terraform_remote_state.paperwork.outputs.env_name
    IAAS_CA_CERT_FILE  = data.terraform_remote_state.paperwork.outputs.iaas_trusted_ca_certs
    KMS_KEY_ID         = data.terraform_remote_state.paperwork.outputs.kms_key_arn
    MIRROR_BUCKET      = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mirror_bucket_name
    OM_PRIVATE_IP      = data.terraform_remote_state.ops-manager.outputs.ops_manager_private_ip
    OPS_MANAGER_BUCKET = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.ops_manager_bucket_name
    PAS_BACKUP_BUCKET  = data.terraform_remote_state.pas.outputs.ops_manager_bucket
    PUBLIC_BUCKET      = data.terraform_remote_state.paperwork.outputs.public_bucket_name
    REGION             = data.terraform_remote_state.paperwork.outputs.region
    REPORTING_BUCKET   = data.terraform_remote_state.paperwork.outputs.reporting_bucket
    ROOT_CA_CERT_FILE  = data.terraform_remote_state.paperwork.outputs.root_ca_cert_path
    S3_ENDPOINT        = data.terraform_remote_state.paperwork.outputs.s3_endpoint
    SMTP_DOMAIN        = data.terraform_remote_state.paperwork.outputs.smtp_domain
    SMTP_FROM          = data.terraform_remote_state.paperwork.outputs.smtp_from
    SMTP_TO            = data.terraform_remote_state.paperwork.outputs.smtp_to
  })
}

resource "aws_s3_bucket_object" "credhub_vars" {
  bucket  = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  key     = local.credhub_vars_key
  content = local.credhub_vars
}

provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "enterprise-services"
    region  = var.remote_state_region
    encrypt = true
  }
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_splunk"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "encrypt_amis"
    region  = var.remote_state_region
    encrypt = true
  }
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  splunk_s3_eni_ids          = data.terraform_remote_state.bootstrap_splunk.outputs.s3_eni_ids
  splunk_master_eni_ids      = data.terraform_remote_state.bootstrap_splunk.outputs.master_eni_ids //[0]
  splunk_indexers_eni_ids    = data.terraform_remote_state.bootstrap_splunk.outputs.indexers_eni_ids
  splunk_forwarders_eni_ids  = data.terraform_remote_state.bootstrap_splunk.outputs.forwarders_eni_ids
  splunk_search_head_eni_ids = data.terraform_remote_state.bootstrap_splunk.outputs.search_head_eni_ids //[0]

  splunk_http_collector_port = module.splunk_ports.splunk_http_collector_port
  splunk_mgmt_port           = module.splunk_ports.splunk_mgmt_port
  splunk_replication_port    = module.splunk_ports.splunk_replication_port
  splunk_syslog_port         = module.splunk_ports.splunk_tcp_port
  splunk_web_port            = module.splunk_ports.splunk_web_port

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-splunk"
    },
  )

  archive_role_name = data.terraform_remote_state.paperwork.outputs.archive_role_name
  splunk_role_name  = data.terraform_remote_state.paperwork.outputs.splunk_role_name

  indexers_pass4SymmKey     = data.terraform_remote_state.bootstrap_splunk.outputs.indexers_pass4SymmKey
  forwarders_pass4SymmKey   = data.terraform_remote_state.bootstrap_splunk.outputs.forwarders_pass4SymmKey
  search_heads_pass4SymmKey = data.terraform_remote_state.bootstrap_splunk.outputs.search_heads_pass4SymmKey

  master_ip = data.terraform_remote_state.bootstrap_splunk.outputs.master_private_ips[0]

  root_domain  = data.terraform_remote_state.paperwork.outputs.root_domain
  bastion_host = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip

  s3_archive_ip     = data.terraform_remote_state.bootstrap_splunk.outputs.s3_private_ips[0]
  s3_archive_port   = module.splunk_ports.splunk_s3_archive_port
  s3_syslog_archive = data.terraform_remote_state.bootstrap_splunk.outputs.s3_bucket_syslog_archive

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url

  encrypted_amazon2_ami_id = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id
}

module "s3_archiver_user_data" {
  source = "./modules/s3-archiver"

  server_cert = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_cert
  server_key  = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_key
  ca_cert     = data.terraform_remote_state.paperwork.outputs.trusted_with_additional_ca_certs
  root_domain = local.root_domain

  clamav_user_data = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data

  s3_syslog_archive       = data.terraform_remote_state.bootstrap_splunk.outputs.s3_bucket_syslog_archive
  s3_syslog_audit_archive = data.terraform_remote_state.bootstrap_splunk.outputs.s3_bucket_syslog_audit_archive
  user_accounts_user_data = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  public_bucket_name      = local.public_bucket_name
  public_bucket_url       = local.public_bucket_url
  banner_user_data        = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  region                  = var.region
}

module "splunk_s3" {
  source         = "../../modules/launch"
  instance_count = length(local.splunk_s3_eni_ids)
  ami_id         = local.encrypted_amazon2_ami_id
  instance_type  = var.instance_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.env_name}-splunk-s3"
    },
  )
  iam_instance_profile = local.archive_role_name

  eni_ids = local.splunk_s3_eni_ids

  user_data = module.s3_archiver_user_data.user_data

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.bastion_host
  volume_ids   = [data.terraform_remote_state.bootstrap_splunk.outputs.s3_data_volume]
  device_name  = "/dev/sdf"
}

module "indexers_user_data" {
  source = "./modules/indexers"

  server_cert               = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_cert
  server_key                = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_key
  ca_cert                   = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  indexers_pass4SymmKey     = local.indexers_pass4SymmKey
  search_heads_pass4SymmKey = local.search_heads_pass4SymmKey
  user_accounts_user_data   = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  root_domain               = local.root_domain

  clamav_user_data = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data

  splunk_password    = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_password
  splunk_rpm_version = var.splunk_rpm_version
  region             = var.region
  master_ip          = local.master_ip
  public_bucket_name = local.public_bucket_name
  public_bucket_url  = local.public_bucket_url
  banner_user_data   = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
}

module "splunk_indexers" {
  source         = "../../modules/launch"
  instance_count = length(local.splunk_indexers_eni_ids)
  ami_id         = local.encrypted_amazon2_ami_id
  instance_type  = var.instance_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.env_name}-splunk-indexer"
    },
  )
  iam_instance_profile = local.splunk_role_name

  eni_ids = local.splunk_indexers_eni_ids

  user_data = module.indexers_user_data.user_data

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.bastion_host
  volume_ids   = data.terraform_remote_state.bootstrap_splunk.outputs.indexers_data_volumes
  device_name  = "/dev/sdf"
}

module "master_user_data" {
  source = "./modules/master"

  server_cert               = data.terraform_remote_state.paperwork.outputs.splunk_monitor_server_cert
  server_key                = data.terraform_remote_state.paperwork.outputs.splunk_monitor_server_key
  ca_cert                   = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  indexers_pass4SymmKey     = local.indexers_pass4SymmKey
  forwarders_pass4SymmKey   = local.forwarders_pass4SymmKey
  search_heads_pass4SymmKey = local.search_heads_pass4SymmKey
  license_path              = "splunk.license"
  user_accounts_user_data   = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  root_domain               = local.root_domain

  clamav_user_data = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data

  splunk_password    = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_password
  splunk_rpm_version = var.splunk_rpm_version
  region             = var.region
  public_bucket_name = local.public_bucket_name
  public_bucket_url  = local.public_bucket_url
  banner_user_data   = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
}

module "splunk_master" {
  source         = "../../modules/launch"
  instance_count = length(local.splunk_master_eni_ids)
  ami_id         = local.encrypted_amazon2_ami_id
  instance_type  = var.instance_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.env_name}-splunk-master"
    },
  )
  iam_instance_profile = local.splunk_role_name

  eni_ids = local.splunk_master_eni_ids

  user_data = module.master_user_data.user_data

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.bastion_host
  volume_ids   = [data.terraform_remote_state.bootstrap_splunk.outputs.master_data_volume]
  device_name  = "/dev/sdf"
}

module "search_head_user_data" {
  source = "./modules/search-head"

  server_cert               = data.terraform_remote_state.paperwork.outputs.splunk_server_cert
  server_key                = data.terraform_remote_state.paperwork.outputs.splunk_server_key
  ca_cert                   = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  indexers_pass4SymmKey     = local.indexers_pass4SymmKey
  forwarders_pass4SymmKey   = local.forwarders_pass4SymmKey
  search_heads_pass4SymmKey = local.search_heads_pass4SymmKey
  user_accounts_user_data   = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  root_domain               = local.root_domain

  clamav_user_data = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data

  splunk_password    = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_password
  splunk_rpm_version = var.splunk_rpm_version
  region             = var.region
  master_ip          = local.master_ip
  public_bucket_name = local.public_bucket_name
  public_bucket_url  = local.public_bucket_url
  banner_user_data   = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
}

module "splunk_search_head" {
  source         = "../../modules/launch"
  instance_count = length(local.splunk_search_head_eni_ids)
  ami_id         = local.encrypted_amazon2_ami_id
  instance_type  = var.instance_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.env_name}-splunk-search-head"
    },
  )
  iam_instance_profile = local.splunk_role_name

  eni_ids = local.splunk_search_head_eni_ids

  user_data = module.search_head_user_data.user_data

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.bastion_host
  volume_ids   = [data.terraform_remote_state.bootstrap_splunk.outputs.search_head_data_volume]
  device_name  = "/dev/sdf"
}

module "forwarders_user_data" {
  source = "./modules/forwarders"

  server_cert             = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_cert
  server_key              = data.terraform_remote_state.paperwork.outputs.splunk_logs_server_key
  ca_cert                 = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  forwarders_pass4SymmKey = local.forwarders_pass4SymmKey
  user_accounts_user_data = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  root_domain             = local.root_domain

  clamav_user_data = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data

  splunk_password             = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_password
  splunk_rpm_version          = var.splunk_rpm_version
  region                      = var.region
  master_ip                   = local.master_ip
  splunk_http_collector_token = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_http_collector_token
  s3_archive_ip               = local.s3_archive_ip
  s3_archive_port             = local.s3_archive_port
  public_bucket_name          = local.public_bucket_name
  public_bucket_url           = local.public_bucket_url
  banner_user_data            = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
}

module "splunk_forwarders" {
  source         = "../../modules/launch"
  instance_count = length(local.splunk_forwarders_eni_ids)
  ami_id         = local.encrypted_amazon2_ami_id
  instance_type  = var.instance_type
  tags = merge(
    local.tags,
    {
      "Name" = "${var.env_name}-splunk-forwarder"
    },
  )
  iam_instance_profile = local.splunk_role_name

  eni_ids = local.splunk_forwarders_eni_ids

  user_data = module.forwarders_user_data.user_data

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.bastion_host
  volume_ids   = data.terraform_remote_state.bootstrap_splunk.outputs.forwarders_data_volumes
  device_name  = "/dev/sdf"
}

resource "aws_elb_attachment" "splunk_master_attach" {
  elb      = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_monitor_elb_id
  instance = module.splunk_master.instance_ids[0]
}

resource "aws_elb_attachment" "splunk_search_head_attach" {
  elb      = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_search_head_elb_id
  instance = module.splunk_search_head.instance_ids[0]
}


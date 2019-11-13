provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "enterprise-services"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
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

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_splunk"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  splunk_s3_eni_id          = "${data.terraform_remote_state.bootstrap_splunk.s3_eni_ids}"
  splunk_master_eni_id      = "${data.terraform_remote_state.bootstrap_splunk.master_eni_ids[0]}"
  splunk_indexers_eni_ids   = "${data.terraform_remote_state.bootstrap_splunk.indexers_eni_ids}"
  splunk_forwarders_eni_ids = "${data.terraform_remote_state.bootstrap_splunk.forwarders_eni_ids}"
  splunk_search_head_eni_id = "${data.terraform_remote_state.bootstrap_splunk.search_head_eni_ids[0]}"

  splunk_http_collector_port = "${module.splunk_ports.splunk_http_collector_port}"
  splunk_mgmt_port           = "${module.splunk_ports.splunk_mgmt_port}"
  splunk_replication_port    = "${module.splunk_ports.splunk_replication_port}"
  splunk_syslog_port         = "${module.splunk_ports.splunk_tcp_port}"
  splunk_web_port            = "${module.splunk_ports.splunk_web_port}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-splunk"))}"

  archive_role_name = "${data.terraform_remote_state.paperwork.archive_role_name}"
  splunk_role_name  = "${data.terraform_remote_state.paperwork.splunk_role_name}"

  indexers_pass4SymmKey     = "${data.terraform_remote_state.bootstrap_splunk.indexers_pass4SymmKey}"
  forwarders_pass4SymmKey   = "${data.terraform_remote_state.bootstrap_splunk.forwarders_pass4SymmKey}"
  search_heads_pass4SymmKey = "${data.terraform_remote_state.bootstrap_splunk.search_heads_pass4SymmKey}"

  master_ip = "${data.terraform_remote_state.bootstrap_splunk.master_private_ips[0]}"

  ssh_key_pair_name = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"

  s3_archive_ip     = "${data.terraform_remote_state.bootstrap_splunk.s3_private_ips[0]}"
  s3_archive_port   = "${module.splunk_ports.splunk_s3_archive_port}"
  s3_syslog_archive = "${data.terraform_remote_state.bootstrap_splunk.s3_bucket_syslog_archive}"

  public_bucket_name = "${data.terraform_remote_state.paperwork.public_bucket_name}"
  public_bucket_url  = "${data.terraform_remote_state.paperwork.public_bucket_url}"
}

module "amazon_ami" {
  source = "../../modules/amis/encrypted/amazon2/lookup"
}

module "s3_archiver_user_data" {
  source = "./modules/s3-archiver"

  server_cert = "${data.terraform_remote_state.paperwork.splunk_logs_server_cert}"
  server_key  = "${data.terraform_remote_state.paperwork.splunk_logs_server_key}"
  ca_cert     = "${data.terraform_remote_state.paperwork.trusted_with_additional_ca_certs}"
  root_domain = "${local.root_domain}"

  clamav_user_data = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"

  s3_syslog_archive       = "${data.terraform_remote_state.bootstrap_splunk.s3_bucket_syslog_archive}"
  user_accounts_user_data = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  public_bucket_name      = "${local.public_bucket_name}"
  public_bucket_url       = "${local.public_bucket_url}"
  banner_user_data        = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
  s3_region               = "${var.splunk_rpm_s3_region}"
}

module "splunk_s3" {
  source               = "../../modules/launch"
  instance_count       = 1
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-s3"))}"
  iam_instance_profile = "${local.archive_role_name}"

  eni_ids = [
    "${local.splunk_s3_eni_id}",
  ]

  user_data = "${module.s3_archiver_user_data.user_data}"
}

module "indexers_user_data" {
  source = "./modules/indexers"

  server_cert               = "${data.terraform_remote_state.paperwork.splunk_logs_server_cert}"
  server_key                = "${data.terraform_remote_state.paperwork.splunk_logs_server_key}"
  ca_cert                   = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
  indexers_pass4SymmKey     = "${local.indexers_pass4SymmKey}"
  search_heads_pass4SymmKey = "${local.search_heads_pass4SymmKey}"
  user_accounts_user_data   = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  root_domain               = "${local.root_domain}"

  clamav_user_data = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"

  splunk_password      = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
  splunk_rpm_version   = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
  master_ip            = "${local.master_ip}"
  public_bucket_name   = "${local.public_bucket_name}"
  public_bucket_url    = "${local.public_bucket_url}"
  banner_user_data     = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
}

module "splunk_indexers" {
  source               = "../../modules/launch"
  instance_count       = "${length(local.splunk_indexers_eni_ids)}"
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-indexer"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = "${local.splunk_indexers_eni_ids}"

  user_data = "${module.indexers_user_data.user_data}"
}

module "master_user_data" {
  source = "./modules/master"

  server_cert               = "${data.terraform_remote_state.paperwork.splunk_monitor_server_cert}"
  server_key                = "${data.terraform_remote_state.paperwork.splunk_monitor_server_key}"
  ca_cert                   = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
  indexers_pass4SymmKey     = "${local.indexers_pass4SymmKey}"
  forwarders_pass4SymmKey   = "${local.forwarders_pass4SymmKey}"
  search_heads_pass4SymmKey = "${local.search_heads_pass4SymmKey}"
  license_path              = "${var.license_path}"
  user_accounts_user_data   = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  root_domain               = "${local.root_domain}"

  clamav_user_data = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"

  splunk_password      = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
  splunk_rpm_version   = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
  public_bucket_name   = "${local.public_bucket_name}"
  public_bucket_url    = "${local.public_bucket_url}"
  banner_user_data     = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
}

module "splunk_master" {
  source               = "../../modules/launch"
  instance_count       = 1
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-master"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = [
    "${local.splunk_master_eni_id}",
  ]

  user_data = "${module.master_user_data.user_data}"
}

module "search_head_user_data" {
  source = "./modules/search-head"

  server_cert               = "${data.terraform_remote_state.paperwork.splunk_server_cert}"
  server_key                = "${data.terraform_remote_state.paperwork.splunk_server_key}"
  ca_cert                   = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
  indexers_pass4SymmKey     = "${local.indexers_pass4SymmKey}"
  forwarders_pass4SymmKey   = "${local.forwarders_pass4SymmKey}"
  search_heads_pass4SymmKey = "${local.search_heads_pass4SymmKey}"
  user_accounts_user_data   = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  root_domain               = "${local.root_domain}"

  clamav_user_data = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"

  splunk_password      = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
  splunk_rpm_version   = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
  master_ip            = "${local.master_ip}"
  public_bucket_name   = "${local.public_bucket_name}"
  public_bucket_url    = "${local.public_bucket_url}"
  banner_user_data     = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
}

module "splunk_search_head" {
  source               = "../../modules/launch"
  instance_count       = 1
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-search-head"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = [
    "${local.splunk_search_head_eni_id}",
  ]

  user_data = "${module.search_head_user_data.user_data}"
}

module "forwarders_user_data" {
  source = "./modules/forwarders"

  server_cert             = "${data.terraform_remote_state.paperwork.splunk_logs_server_cert}"
  server_key              = "${data.terraform_remote_state.paperwork.splunk_logs_server_key}"
  ca_cert                 = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
  forwarders_pass4SymmKey = "${local.forwarders_pass4SymmKey}"
  user_accounts_user_data = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  root_domain             = "${local.root_domain}"

  clamav_user_data = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"

  splunk_password             = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
  splunk_rpm_version          = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket        = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region        = "${var.splunk_rpm_s3_region}"
  master_ip                   = "${local.master_ip}"
  splunk_http_collector_token = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_token}"
  s3_archive_ip               = "${local.s3_archive_ip}"
  s3_archive_port             = "${local.s3_archive_port}"
  public_bucket_name          = "${local.public_bucket_name}"
  public_bucket_url           = "${local.public_bucket_url}"
  banner_user_data            = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
}

module "splunk_forwarders" {
  source               = "../../modules/launch"
  instance_count       = "${length(local.splunk_forwarders_eni_ids)}"
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-forwarder"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = "${local.splunk_forwarders_eni_ids}"

  user_data = "${module.forwarders_user_data.user_data}"
}

resource "aws_volume_attachment" "splunk_s3_volume_attachment" {
  skip_destroy = true

  instance_id = "${module.splunk_s3.instance_ids[0]}"
  volume_id   = "${data.terraform_remote_state.bootstrap_splunk.s3_data_volume}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_master_volume_attachment" {
  skip_destroy = true

  instance_id = "${module.splunk_master.instance_ids[0]}"
  volume_id   = "${data.terraform_remote_state.bootstrap_splunk.master_data_volume}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_search_head_volume_attachment" {
  skip_destroy = true

  instance_id = "${module.splunk_search_head.instance_ids[0]}"
  volume_id   = "${data.terraform_remote_state.bootstrap_splunk.search_head_data_volume}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_indexers_volume_attachment" {
  skip_destroy = true

  count       = "${length(local.splunk_indexers_eni_ids)}"
  instance_id = "${module.splunk_indexers.instance_ids[count.index]}"
  volume_id   = "${element(data.terraform_remote_state.bootstrap_splunk.indexers_data_volumes, count.index)}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_forwarders_volume_attachment" {
  skip_destroy = true

  count       = "${length(local.splunk_forwarders_eni_ids)}"
  instance_id = "${module.splunk_forwarders.instance_ids[count.index]}"
  volume_id   = "${element(data.terraform_remote_state.bootstrap_splunk.forwarders_data_volumes, count.index)}"
  device_name = "/dev/sdf"
}

resource "aws_elb_attachment" "splunk_master_attach" {
  elb      = "${data.terraform_remote_state.bootstrap_splunk.splunk_monitor_elb_id}"
  instance = "${module.splunk_master.instance_ids[0]}"
}

resource "aws_elb_attachment" "splunk_search_head_attach" {
  elb      = "${data.terraform_remote_state.bootstrap_splunk.splunk_search_head_elb_id}"
  instance = "${module.splunk_search_head.instance_ids[0]}"
}

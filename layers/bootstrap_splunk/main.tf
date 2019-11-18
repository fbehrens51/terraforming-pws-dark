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

data "terraform_remote_state" "bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  indexers_count   = "3"
  forwarders_count = "1"

  cert_bucket = "${replace(var.env_name," ","-")}-syslog-archive"
  tags        = "${merge(var.tags, map("Name", "${var.env_name}-splunk"))}"

  dns_zone_name    = "${data.terraform_remote_state.paperwork.root_domain}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  bind_rndc_secret = "${data.terraform_remote_state.bootstrap_bind.bind_rndc_secret}"
  public_subnet    = "${data.terraform_remote_state.enterprise-services.public_subnet_ids[0]}"

  private_subnets            = "${data.terraform_remote_state.enterprise-services.private_subnet_ids}"
  master_private_subnet      = "${local.private_subnets[0]}"
  search_head_private_subnet = "${local.private_subnets[0]}"
  private_subnet_cidrs       = "${data.terraform_remote_state.enterprise-services.private_subnet_cidrs}"

  splunk_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_replication_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_mgmt_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_web_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_tcp_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_http_collector_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "${module.splunk_ports.splunk_s3_archive_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  splunk_egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "internetless" {}

variable "env_name" {}

variable "splunk_host_key_pair_name" {}

variable "tags" {
  type = "map"
}

module "s3_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules  = "${local.splunk_egress_rules}"
  subnet_ids    = ["${local.private_subnets}"]
  eni_count     = "${local.forwarders_count}"
  create_eip    = "false"
  tags          = "${local.tags}"
}

module "master_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules  = "${local.splunk_egress_rules}"
  subnet_ids    = ["${local.master_private_subnet}"]
  eni_count     = "1"
  create_eip    = "false"
  tags          = "${local.tags}"
}

module "forwarders_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules  = "${local.splunk_egress_rules}"
  subnet_ids    = ["${local.private_subnets}"]
  eni_count     = "${local.forwarders_count}"
  create_eip    = "false"
  tags          = "${local.tags}"
}

module "indexers_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules  = "${local.splunk_egress_rules}"
  subnet_ids    = ["${local.private_subnets}"]
  eni_count     = "${local.indexers_count}"
  create_eip    = "false"
  tags          = "${local.tags}"
}

module "search_head_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules  = "${local.splunk_egress_rules}"
  subnet_ids    = ["${local.search_head_private_subnet}"]
  eni_count     = "1"
  create_eip    = "false"
  tags          = "${local.tags}"
}

resource "aws_s3_bucket" "syslog_archive" {
  bucket = "${local.cert_bucket}"
  acl    = "private"
  tags   = "${local.tags}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "random_uuid" "splunk_http_token" {}

resource "random_string" "splunk_password" {
  length  = "32"
  special = false
}

resource "random_string" "cf_splunk_password" {
  length  = "32"
  special = false
}

resource "random_string" "indexers_pass4SymmKey" {
  length  = "32"
  special = false
}

resource "random_string" "forwarders_pass4SymmKey" {
  length  = "32"
  special = false
}

resource "random_string" "search_heads_pass4SymmKey" {
  length  = "32"
  special = false
}

# TODO: Do not create key pairs or parameterize their creation, they should not
# be used on location accounts should be created as part of user data.  Should
# we create a module to generate?
module "splunk_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.splunk_host_key_pair_name}"
}

data "aws_subnet" "private_subnets" {
  count = "${length(local.private_subnets)}"
  id    = "${local.private_subnets[count.index]}"
}

resource "aws_ebs_volume" "splunk_s3_data" {
  availability_zone = "${element(data.aws_subnet.private_subnets.*.availability_zone, 0)}"
  size              = 100
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

resource "aws_ebs_volume" "splunk_master_data" {
  availability_zone = "${element(data.aws_subnet.private_subnets.*.availability_zone, 0)}"
  size              = 1000
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

resource "aws_ebs_volume" "splunk_search_head_data" {
  availability_zone = "${element(data.aws_subnet.private_subnets.*.availability_zone, 0)}"
  size              = 1000
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

resource "aws_ebs_volume" "splunk_indexers_data" {
  count             = "${local.indexers_count}"
  availability_zone = "${element(data.aws_subnet.private_subnets.*.availability_zone, count.index % length(data.aws_subnet.private_subnets.*.availability_zone))}"
  size              = 1000
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

resource "aws_ebs_volume" "splunk_forwarders_data" {
  count             = "${local.forwarders_count}"
  availability_zone = "${element(data.aws_subnet.private_subnets.*.availability_zone, count.index % length(data.aws_subnet.private_subnets.*.availability_zone))}"
  size              = 100
  encrypted         = true
  kms_key_id        = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

module "splunk_search_head_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = ["${local.public_subnet}"]
  tags              = "${var.tags}"
  vpc_id            = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  egress_cidrs      = ["${local.private_subnet_cidrs}"]
  short_name        = "splunk-sh"
  port              = "443"
  instance_port     = "8000"
}

# TODO: For now splunk-monitor is pointing to the master instance.  This way
# operators can check on the status of replication.  In the future we could add
# another splunk instance setup for distributed monitoring.
# https://docs.splunk.com/Documentation/Splunk/7.3.0/DMC/Configureindistributedmode
module "splunk_monitor_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = ["${local.public_subnet}"]
  tags              = "${var.tags}"
  vpc_id            = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  egress_cidrs      = ["${local.private_subnet_cidrs}"]
  short_name        = "splunk-monitor"
  port              = "443"
  instance_port     = "8000"
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"
}

provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

resource "dns_cname_record" "splunk_master_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "${module.domains.splunk_monitor_subdomain}"
  cname = "${module.splunk_monitor_elb.dns_name}."
  ttl   = 300
}

resource "dns_cname_record" "splunk_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "${module.domains.splunk_subdomain}"
  cname = "${module.splunk_search_head_elb.dns_name}."
  ttl   = 300
}

resource "dns_a_record_set" "splunk_logs_a_record" {
  zone      = "${local.dns_zone_name}."
  name      = "${module.domains.splunk_logs_subdomain}"
  addresses = ["${module.forwarders_bootstrap.eni_ips}"]
  ttl       = 300
}

output "s3_bucket_syslog_archive" {
  value = "${aws_s3_bucket.syslog_archive.id}"
}

output "s3_data_volume" {
  value = "${aws_ebs_volume.splunk_s3_data.id}"
}

output "master_data_volume" {
  value = "${aws_ebs_volume.splunk_master_data.id}"
}

output "search_head_data_volume" {
  value = "${aws_ebs_volume.splunk_search_head_data.id}"
}

output "indexers_data_volumes" {
  value = "${aws_ebs_volume.splunk_indexers_data.*.id}"
}

output "forwarders_data_volumes" {
  value = "${aws_ebs_volume.splunk_forwarders_data.*.id}"
}

output "indexers_private_ips" {
  value = "${module.indexers_bootstrap.eni_ips}"
}

output "search_head_private_ips" {
  value = "${module.search_head_bootstrap.eni_ips}"
}

output "s3_private_ips" {
  value = "${module.s3_bootstrap.eni_ips}"
}

output "master_private_ips" {
  value = "${module.master_bootstrap.eni_ips}"
}

output "s3_eni_ids" {
  value = "${module.s3_bootstrap.eni_ids}"
}

output "master_eni_ids" {
  value = "${module.master_bootstrap.eni_ids}"
}

output "indexers_eni_ids" {
  value = "${module.indexers_bootstrap.eni_ids}"
}

output "forwarders_private_ips" {
  value = "${module.forwarders_bootstrap.eni_ips}"
}

output "forwarders_eni_ids" {
  value = "${module.forwarders_bootstrap.eni_ids}"
}

output "search_head_eni_ids" {
  value = "${module.search_head_bootstrap.eni_ids}"
}

output "splunk_http_collector_url" {
  value = "https://${module.domains.splunk_logs_fqdn}:${module.splunk_ports.splunk_http_collector_port}"
}

output "splunk_ssh_key_pair_name" {
  value     = "${module.splunk_host_key_pair.key_name}"
  sensitive = true
}

output "splunk_ssh_key" {
  value     = "${module.splunk_host_key_pair.private_key_pem}"
  sensitive = true
}

output "splunk_http_collector_token" {
  value     = "${random_uuid.splunk_http_token.result}"
  sensitive = true
}

output "forwarders_pass4SymmKey" {
  value     = "${random_string.forwarders_pass4SymmKey.result}"
  sensitive = true
}

output "search_heads_pass4SymmKey" {
  value     = "${random_string.search_heads_pass4SymmKey.result}"
  sensitive = true
}

output "indexers_pass4SymmKey" {
  value     = "${random_string.indexers_pass4SymmKey.result}"
  sensitive = true
}

output "splunk_password" {
  value     = "${random_string.splunk_password.result}"
  sensitive = true
}

output "cf_splunk_password" {
  value     = "${random_string.cf_splunk_password.result}"
  sensitive = true
}

output "splunk_monitor_elb_id" {
  value = "${module.splunk_monitor_elb.my_elb_id}"
}

output "splunk_search_head_elb_id" {
  value = "${module.splunk_search_head_elb.my_elb_id}"
}

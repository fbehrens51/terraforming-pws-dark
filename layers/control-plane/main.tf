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
    bucket     = "${var.remote_state_bucket}"
    key        = "paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "bootstrap_bind" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "bootstrap_bind"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "bind" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "bind"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "aws_vpc" "vpc" {
  id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix = "${local.bucket_suffix}"
  env_name      = "${local.env_name}"
  om_eip        = "${!var.internetless}"
  private       = false
  subnet_id     = "${module.public_subnets.subnet_ids[0]}"
  tags          = "${local.modified_tags}"
  vpc_id        = "${local.vpc_id}"
  ingress_rules = ["${local.om_ingress_rules}"]
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = ["${var.availability_zones}"]
  vpc_id             = "${data.aws_vpc.vpc.id}"
  cidr_block         = "${local.public_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-public"))}"
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = "${length(module.public_subnets.subnet_ids)}"
  subnet_id      = "${module.public_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.cp_public_vpc_route_table_id}"
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = ["${var.availability_zones}"]
  vpc_id             = "${data.aws_vpc.vpc.id}"
  cidr_block         = "${local.private_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-private"))}"
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = "${length(module.private_subnets.subnet_ids)}"
  subnet_id      = "${module.private_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.cp_private_vpc_route_table_id}"
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.om_key_name}"
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(local.modified_tags, map("Name", "${local.env_name}-vms-security-group"))}"
}

module "nat" {
  source                 = "../../modules/nat"
  private_route_table_id = "${data.terraform_remote_state.routes.cp_private_vpc_route_table_id}"
  tags                   = "${local.modified_tags}"
  public_subnet_id       = "${module.public_subnets.subnet_ids[0]}"
  internetless           = "${var.internetless}"
  instance_type          = "${var.nat_instance_type}"
}

module "web_elb" {
  source            = "../../modules/two_port_elb/create"
  env_name          = "${local.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.public_subnets.subnet_ids}"
  tags              = "${var.tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.private_subnets.subnet_cidr_blocks}"
  short_name        = "web"
  port              = 443
  additional_port   = 2222
}

module "uaa_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${local.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.public_subnets.subnet_ids}"
  tags              = "${var.tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.private_subnets.subnet_cidr_blocks}"
  short_name        = "uaa"
  port              = 443
  instance_port     = 8443
}

module "credhub_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${local.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.public_subnets.subnet_ids}"
  tags              = "${var.tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.private_subnets.subnet_cidr_blocks}"
  short_name        = "credhub"
  port              = 443
  instance_port     = 8844
}

# Configure the DNS Provider
provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

resource "dns_a_record_set" "om_a_record" {
  zone      = "${local.dns_zone_name}."
  name      = "om.ci"
  addresses = ["${module.ops_manager.ip}"]
  ttl       = 300
}

resource "dns_cname_record" "atc_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "plane.ci"
  cname = "${module.web_elb.dns_name}."
  ttl   = 300
}

resource "dns_cname_record" "uaa_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "uaa.ci"
  cname = "${module.uaa_elb.dns_name}."
  ttl   = 300
}

resource "dns_cname_record" "credhub_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "credhub.ci"
  cname = "${module.credhub_elb.dns_name}."
  ttl   = 300
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

data "aws_vpc" "bastion_vpc" {
  id = "${local.bastion_vpc_id}"
}

locals {
  bastion_vpc_id   = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  vpc_id           = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  bucket_suffix    = "${random_integer.bucket.result}"
  om_key_name      = "${local.env_name}-cp-om"
  bind_rndc_secret = "${data.terraform_remote_state.bootstrap_bind.bind_rndc_secret}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  dns_zone_name    = "${data.terraform_remote_state.bind.zone_name}"
  env_name         = "${var.tags["Name"]}"
  modified_name    = "${local.env_name} control plane"
  modified_tags    = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

  public_cidr_block  = "${cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 0)}"
  private_cidr_block = "${cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 1)}"
  sjb_cidr_block     = "${cidrsubnet(local.private_cidr_block, 2, 3)}"

  om_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "${data.aws_vpc.bastion_vpc.cidr_block}"
    },
    {
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${var.user_data_path}")}"
  }
}

module "sjb_subnet" {
  source             = "../../modules/subnet_per_az"
  availability_zones = "${list(var.singleton_availability_zone)}"
  vpc_id             = "${data.aws_vpc.vpc.id}"
  cidr_block         = "${local.sjb_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-sjb"))}"
}

resource "aws_route_table_association" "sjb_route_table_assoc" {
  count          = "1"
  subnet_id      = "${module.sjb_subnet.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.cp_private_vpc_route_table_id}"
}

module "sjb_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${var.sjb_ingress_rules}"
  egress_rules  = "${var.sjb_egress_rules}"
  subnet_ids    = ["${module.sjb_subnet.subnet_ids}"]
  eni_count     = "1"
  create_eip    = "false"
  tags          = "${local.modified_tags}"
}

module "find_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

module "sjb_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.control_plane_host_key_pair_name}"
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = "${module.find_ami.id}"
  user_data            = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids              = "${module.sjb_bootstrap.eni_ids}"
  key_pair_name        = "${module.sjb_key_pair.key_name}"
  iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"
  instance_type        = "${var.instance_type}"
  tags                 = "${merge(local.modified_tags, map("Name", "${local.env_name}-sjb"))}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }
}

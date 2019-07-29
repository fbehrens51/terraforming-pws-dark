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
    bucket     = "${var.remote_state_bucket}"
    key        = "enterprise-services"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
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

data "terraform_remote_state" "keys" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "keys"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "aws_network_interface" "splunk_eni" {
  id = "${local.splunk_eni_id}"
}

locals {
  splunk_eni_id = "${module.bootstrap.eni_ids[0]}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-splunk"))}"

  splunk_role_name = "${data.terraform_remote_state.paperwork.splunk_role_name}"

  dns_zone_name    = "${data.terraform_remote_state.bind.zone_name}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  bind_rndc_secret = "${data.terraform_remote_state.keys.bind_rndc_secret}"
  public_subnet = "${data.terraform_remote_state.enterprise-services.public_subnet_ids[0]}"

  private_subnet = "${data.terraform_remote_state.enterprise-services.private_subnet_ids[0]}"
  private_subnet_cidr = "${data.terraform_remote_state.enterprise-services.private_subnet_cidrs[0]}"

  # TODO: what should this be
  splunk_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8088"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8089"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8000"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8090"
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

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "internetless" {}

variable "env_name" {}

variable "tags" {
  type = "map"
}

variable "splunk_host_key_pair_name" {}

variable "instance_type" {
  default = "t2.small"
}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

module "bootstrap" {
  source = "../../modules/eni_per_subnet"
  ingress_rules = "${local.splunk_ingress_rules}"
  egress_rules = "${local.splunk_egress_rules}"
  subnet_ids = ["${local.private_subnet}"]
  create_eip = "${var.internetless}"
  tags = "${local.tags}"
}

//TODO: Do not create key pairs or parameterize their creation, they should not be used on location
//accounts should be created as part of user data.  Should we create a module to generate?
module "splunk_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.splunk_host_key_pair_name}"
}

module "splunk_user_data" {
  source = "../../modules/splunk/user_data"
}

module "splunk" {
  source               = "../../modules/launch"
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${module.splunk_host_key_pair.key_name}"
  tags                 = "${local.tags}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = [
    "${local.splunk_eni_id}",
  ]

  user_data = "${module.splunk_user_data.user_data}"
}

resource "aws_ebs_volume" "splunk_data" {
  availability_zone = "${data.aws_network_interface.splunk_eni.availability_zone}"
    size              = 1000
}

//TODO: Best way to ensure we stop instance??? (want to ensure we can cleanly detach volume)
//resource "null_resource" "instance_stopper" {
//  provisioner "local-exec" {
//    when    = "destroy"
//    command = "echo aws ec2 stop-instances --instance-ids ${module.splunk.instance_ids[0]} >> /home/ubuntu/stopper.out"
//  }
//}

resource "aws_volume_attachment" "splunk_volume_attachment" {
  instance_id = "${module.splunk.instance_ids[0]}"
  volume_id   = "${aws_ebs_volume.splunk_data.id}"
  device_name = "/dev/sdf"
}

output "splunk_public_ip" {
  value = "${element(concat(module.bootstrap.public_ips, module.bootstrap.eni_ips), 0)}"
}

output "splunk_password" {
  value     = "${module.splunk_user_data.password}"
  sensitive = true
}

module "splunk_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = ["${local.public_subnet}"]
  tags              = "${var.tags}"
  vpc_id            = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  egress_cidrs      = ["${local.private_subnet_cidr}"]
  short_name        = "splunk"
  port              = "80"
  instance_port     = "8000"
}

resource "aws_elb_attachment" "splunk_attach" {
  elb      = "${module.splunk_elb.my_elb_id}"
  instance = "${module.splunk.instance_ids[0]}"
}

provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

resource "dns_cname_record" "splunk_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "splunk"
  cname = "${module.splunk_elb.dns_name}."
  ttl   = 300
}

output "splunk_dns_name" {
  value = "${dns_cname_record.splunk_cname.name}.${substr(dns_cname_record.splunk_cname.zone, 0, length(dns_cname_record.splunk_cname.zone) - 1)}"
}

output "splunk_syslog_host_name" {
  value = "${module.splunk.private_ips[0]}"
}

output "splunk_syslog_port" {
  value = "8090"
}

output "splunk_private_ips" {
  value = "${module.splunk.private_ips}"
}

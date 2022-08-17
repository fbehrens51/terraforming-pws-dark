variable "iso_seg_name" {
}

variable "iso_seg_tile_suffix" {
}

variable "vanity_cert_enabled" {
}

variable "vanity_cert_pem" {
}

variable "vanity_private_key_pem" {
}

variable "router_cert_pem" {
}

variable "router_private_key_pem" {
}

variable "router_trusted_ca_certificates" {
}

variable "syslog_host" {
}

variable "syslog_port" {
}

variable "syslog_ca_cert" {
}

variable "env_name" {
}

variable "pas_subnet_availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
  type = string
}

variable "secrets_bucket_name" {
}

variable "isolation_segment_config" {
}

variable "scale" {
  type = map(map(string))
}

variable "instance_count" {
  type = number
  default = 5
  description = "Number of Instances"
}

variable "router_enabled" {
  type = bool
  default = false
  description = "enable router"
}

variable "compute_enabled" {
  type = bool
  default = true
  description = "enable compute (diego cells)"
}

variable "elb_name" {
  type = string
  default = ""
  description = "what elb to attach the routers to if enabled"
}

variable "override_vpc_id" {
  type = string
  default = ""
  description = "what vpc to use if not finding based on subnet tags"
}

data "template_file" "pas_vpc_azs" {
  count = length(var.pas_subnet_availability_zones)

  template = <<EOF
- name: $${pas_subnet_availability_zone}
EOF


  vars = {
    pas_subnet_availability_zone = var.pas_subnet_availability_zones[count.index]
  }
}

data "aws_subnet" "isolation_segment_subnets" {
  count = var.override_vpc_id=="" ? length(var.pas_subnet_availability_zones) : 0

  availability_zone = var.pas_subnet_availability_zones[count.index]

  tags = {
    isolation_segment = var.iso_seg_name
    env               = var.env_name
  }
}

data "aws_vpc" "override_vpc" {
  count = var.override_vpc_id=="" ? 0: 1
  id = var.override_vpc_id
}

locals {
  vpc_id = var.override_vpc_id=="" ? data.aws_subnet.isolation_segment_subnets[0].vpc_id : var.override_vpc_id
  network_name = var.override_vpc_id=="" ? "isolation-segment-${var.iso_seg_tile_suffix}" : data.aws_vpc.override_vpc[0].tags["Purpose"]

  compute_isolation = (var.compute_enabled ? "enabled" : "disabled")
  //Will need to enhance this further if we want to support routers gor a given iso-seg vs just the iso-router
  routing_table_sharding_mode = (var.router_enabled ? "no_isolation_segment" : "isolation_segment_only")

  tile_config = templatefile("${path.module}/isolation_segment_template.tpl", {
    scale                          = var.scale["p-isolation-segment"]
    instance_count                 = var.instance_count
    vpc_id                         = local.vpc_id
    iso_seg_tile_suffix            = var.iso_seg_tile_suffix
    iso_seg_tile_suffix_underscore = replace(var.iso_seg_tile_suffix, "-", "_")
    vanity_cert_pem                = var.vanity_cert_pem
    vanity_private_key_pem         = var.vanity_private_key_pem
    vanity_cert_enabled            = var.vanity_cert_enabled
    router_cert_pem                = var.router_cert_pem
    router_private_key_pem         = var.router_private_key_pem
    router_trusted_ca_certificates = var.router_trusted_ca_certificates
    syslog_host                    = var.syslog_host
    syslog_port                    = var.syslog_port
    syslog_ca_cert                 = var.syslog_ca_cert
    pas_vpc_azs                    = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone    = var.singleton_availability_zone
    compute_isolation              = local.compute_isolation
    routing_table_sharding_mode    = local.routing_table_sharding_mode
    elb_name                       = var.elb_name
    compute_enabled                = var.compute_enabled
    router_enabled                 = var.router_enabled
    network_name                   = local.network_name
  })
}

resource "aws_s3_bucket_object" "isolation_segment_template" {
  bucket  = var.secrets_bucket_name
  key     = var.isolation_segment_config
  content = local.tile_config
}

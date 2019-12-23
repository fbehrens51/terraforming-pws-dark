variable "vpc_cidr" {
}

locals {
  pas_cidr_1 = cidrsubnet(var.vpc_cidr, 3, 0)
  pas_cidr_2 = cidrsubnet(var.vpc_cidr, 3, 1)
  pas_cidr_3 = cidrsubnet(var.vpc_cidr, 3, 2)

  # We don't use the OM cidr anymore.  Ops manager is now created in the public
  # subnet.  Feel free to use this cidr block.
  # om_cidr = "${cidrsubnet(var.vpc_cidr, 3, 3)}"
  infra_cidr = cidrsubnet(var.vpc_cidr, 3, 4)

  rds_cidr      = cidrsubnet(var.vpc_cidr, 3, 5)
  services_cidr = cidrsubnet(var.vpc_cidr, 3, 6)
  public_cidr   = cidrsubnet(var.vpc_cidr, 3, 7)
}

output "pas_cidrs" {
  value = [local.pas_cidr_1, local.pas_cidr_2, local.pas_cidr_3]
}

output "infrastructure_cidr" {
  value = local.infra_cidr
}

output "rds_cidr" {
  value = local.rds_cidr
}

output "services_cidr" {
  value = local.services_cidr
}

output "public_cidr" {
  value = local.public_cidr
}


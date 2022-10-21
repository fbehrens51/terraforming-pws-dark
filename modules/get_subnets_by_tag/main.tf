variable "global_vars" {
  type = any
}

variable "vpc_id" {
  type = string
  description = "vpc id for the subnet(s)"
}

variable "subnet_type" {
  type = string
  description = "value of the Type tag, currently PUBLIC or PRIVATE"
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
  tags = merge(var.global_vars["global_tags"],{"Type" = var.subnet_type})
}

#Below data block and subsequent reference to it are to ensure we're sorting by AZ
data "aws_subnet" "subnet" {
  for_each = data.aws_subnet_ids.subnet_ids.ids
  id       = each.value
}

output "subnet_ids_sorted_by_az" {
  value = values({for subnet in data.aws_subnet.subnet :  subnet.availability_zone => subnet.id })
}
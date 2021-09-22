output "sjb_private_ip" {
  value = module.sjb_bootstrap.eni_ips[0]
}

output "sjb_eni_ids" {
  value = module.sjb_bootstrap.eni_ids
}

output "terraform_bucket_name" {
  value = var.terraform_bucket_name
}

//10.1.0.224/27
output "sjb_subnet" {
  value = module.sjb_subnet.subnet_cidr_blocks
}

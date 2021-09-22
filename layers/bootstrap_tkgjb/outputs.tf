output "tkgjb_private_ip" {
  value = module.tkgjb_bootstrap.eni_ips[0]
}

output "tkgjb_eni_ids" {
  value = module.tkgjb_bootstrap.eni_ids
}

output "terraform_bucket_name" {
  value = var.terraform_bucket_name
}

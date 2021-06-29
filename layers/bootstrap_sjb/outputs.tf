output "sjb_private_ip" {
  value = module.sjb_bootstrap.eni_ips[0]
}

output "sjb_eni_ids" {
  value = module.sjb_bootstrap.eni_ids
}

output "terraform_bucket_name" {
  value = var.terraform_bucket_name
}
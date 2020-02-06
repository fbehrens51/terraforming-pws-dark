output "security_group_id" {
  value = aws_security_group.my_elb_sg.id
}

output "my_elb_id" {
  value = module.my_elb.elb_id
}

output "dns_name" {
  value = module.my_elb.dns_name
}


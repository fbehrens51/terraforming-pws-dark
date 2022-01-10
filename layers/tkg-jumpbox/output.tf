output "key_name" {
  value = aws_key_pair.key_pair.key_name
}

output "instance_private_ip" {
  value = aws_instance.tkgjb.private_ip
}

output "instance_public_ip" {
  value = aws_instance.tkgjb.public_ip
}

//tkgjb_private_ip = "10.5.0.253"

output "private_key_pem" {
  value     = tls_private_key.private_key.private_key_pem
  sensitive = true
}

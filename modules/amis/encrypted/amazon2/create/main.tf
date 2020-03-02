variable "kms_key_id" {
}

data "aws_region" "current_region" {
}

module "amazon2_linux_ami" {
  source = "../../../amazon_hvm_ami"
}

resource "aws_ami_copy" "encrypted_amazon2_ami" {
  name              = "encrypted_${module.amazon2_linux_ami.name}"
  source_ami_id     = module.amazon2_linux_ami.id
  source_ami_region = data.aws_region.current_region.name
  encrypted         = true
  kms_key_id        = var.kms_key_id
  description       = "Copy of ${module.amazon2_linux_ami.id}"
}

output "encrypted_ami_id" {
  value = aws_ami_copy.encrypted_amazon2_ami.id
}


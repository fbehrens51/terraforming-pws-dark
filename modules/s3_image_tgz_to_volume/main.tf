variable "region" {
  description = "AWS region"
}

variable "subnet_id" {
  description = "ID of working subnet (to create vm_importer instance needed to support import process)"
}

variable "ami_id" {
  description = "ID of AMI to use for importer VM"
}

variable "bucket_name" {
  description = "bucket to copy image tgz from"
}

variable "s3_object_key" {
  description = "s3 object key of image tgz"
}

variable "security_group_ids" {
  type = "list"
  description = "security_groups_ids to apply to importer vm"
}

variable "enable_public_ip" {
  description = "required if running from outside VPC"
  default = true
}

variable "iam_instance_profile" {
  default = "director"
}

variable "instance_type" {
  description = "instance type os use for importer VM"
  default = "m4.xlarge"
}


locals {
  //TODO: be more flexible, should the two names be parameters, should we allow for non-tarballs, etc?
  //Currently assumes file name has a .img.tgz extension and that name of contained file is same as the name of the tarball minus .tgz
  tmp_split = "${split("/",var.s3_object_key)}"
  downloaded_file_name = "${element(local.tmp_split,length(local.tmp_split)+1)}"
  extracted_image_name = "${substr(local.downloaded_file_name, 0,length(local.downloaded_file_name) - 4)}"
}

provider "aws" {
  region = "${var.region}"
}

module "importer" {
  source = "../instance_to_support_image_dd"
  ami = "${var.ami_id}"
  subnet_id = "${var.subnet_id}"
  region = "${var.region}"
  instance_role = "${var.iam_instance_profile}"
  instance_type = "${var.instance_type}"
  security_group_ids = "${var.security_group_ids}"
  enable_public_ip = "${var.enable_public_ip}"
}

resource "null_resource" "upload_file" {
  depends_on = [
    "module.importer"]
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${module.importer.vm_importer_private_key}"
    host = "${module.importer.vm_importer_public_ip}"
    timeout = "120m"

  }
  provisioner "remote-exec" {
    inline = [
      "export AWS_DEFAULT_REGION=${var.region}",
      "aws s3 cp s3://${var.bucket_name}/${var.s3_object_key} ${local.downloaded_file_name} --only-show-errors"
    ]
  }
  triggers {
    instance_id = "${module.importer.vm_importer_volume_id}"
  }
}

resource "null_resource" "extract_file" {
  depends_on = [
    "null_resource.upload_file"]
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${module.importer.vm_importer_private_key}"
    host = "${module.importer.vm_importer_public_ip}"
    timeout = "60m"
  }
  provisioner "remote-exec" {
    inline = [
      "tar xvf ${local.downloaded_file_name}",
      "rm -rf ${local.downloaded_file_name}",
    ]
  }
  triggers {
    file_id = "${null_resource.upload_file.id}"
  }
}


resource "null_resource" "apply_image_to_volume" {
  depends_on = [
    "null_resource.extract_file"]
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${module.importer.vm_importer_private_key}"
    host = "${module.importer.vm_importer_public_ip}"
    timeout = "60m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo dd of=/dev/xvdf if=/home/ec2-user/${local.extracted_image_name} bs=5M oflag=direct",
    ]
  }

  triggers {
    file_id = "${null_resource.extract_file.id}"
  }
}

output "priv_key" {
  value = "${module.importer.vm_importer_private_key}"
  sensitive = true
}

output "extracted_image_name" {
  value = "${local.extracted_image_name}"
}

output "volume_id" {
  value = "${module.importer.vm_importer_volume_id}"
}

output "vm_importer_host" {
  value = "${module.importer.vm_importer_host}"
}

output "public_ip" {
  value = "${module.importer.vm_importer_public_ip}"
}

output "private_ip" {
  value = "${module.importer.vm_importer_private_ip}"
}
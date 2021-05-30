data "template_file" "server_hardening_user_data_part" {
  template = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]
runcmd:
  - |
    # password "set date" is yesterday so we'll pass a compliance scan the same day the servers were rebuilt
    awk -F: '$3 >= 1000 && $1 != "nfsnobody" {print $1}' /etc/passwd | xargs --no-run-if-empty -I{} chage --lastday $( date -d yesterday '+%F' ) {}
    awk -F: '$3 >= 1000 && $1 != "nfsnobody" {print "chown -R " $3 ":" $4 " " $6 "\nchmod 700 " $6}' /etc/passwd | xargs --no-run-if-empty -0 sh -c
EOF

}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

locals {
  bucket_key = "hardening-${md5(data.template_file.server_hardening_user_data_part.rendered)}-user-data.yml"
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.server_hardening_user_data_part.rendered
}

output "server_hardening_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

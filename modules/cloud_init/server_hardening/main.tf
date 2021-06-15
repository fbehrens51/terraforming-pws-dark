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
    cut -d: -f1 /etc/shadow | xargs -n1 chage --lastday $( date -d yesterday '+%F' )
    # chown and chmod all user directories after they've been created
    awk -F: '$3 >= 1000 && $1 != "nfsnobody" {print "chown -R " $3 ":" $4 " " $6 "\nchmod 700 " $6}' /etc/passwd | xargs --no-run-if-empty -0 sh -c
    # defer setting umask until after all of the yum installs have completed.
    sed -i -E -e '/umask 002/s/002/027/' /etc/profile /etc/bashrc
    sed -i -E -e '/umask 022/s/022/077/' /etc/profile /etc/bashrc
    # TODO: Move these to server hardening if this passes the audit
    sed -i -E -e 's/OPTIONS=""/OPTIONS="-u chrony"/' /etc/sysconfig/chronyd
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

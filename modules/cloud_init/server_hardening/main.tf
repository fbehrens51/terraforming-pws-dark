data "template_file" "server_hardening_user_data_part" {
  template = <<EOF
#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]
write_files:
  - path: /root/aide.bash
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -e

      source /etc/profile.d/aws.sh

      if ! aide_report="$( /sbin/aide --check 2>&1 )"; then
        report_file="$ssh_host_name-aide_check-$(date '+%s')"
        bucket_file="s3://$reporting_bucket/aide/$ssh_host_name/$report_file"
        echo "$aide_report" > "$report_file"
        aws s3 cp $report_file "$bucket_file" --quiet
        email_report=$( printf "%s\n\n%s" "$(awk '/^Start timestamp/,/Changed entries/ {print} /^End timestamp/ {print "\n" $0}' $report_file )" "Full report copied to $bucket_file" )
        rm $report_file

        mailx -s "Aide Check <root@$ssh_host_name> /root/aide.bash" root <<< "$email_report"
      else
        mailx -s "Aide Check Error<root@$ssh_host_name> /root/aide.bash" root <<< "$aide_report"
      fi
  - path: /root/aide-update.bash
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -e

      source /etc/profile.d/aws.sh

      if ! aide_report="$(aide --update 2>&1)"; then
        report_file="$ssh_host_name-aide_check-$(date '+%s')"
        bucket_file="s3://$reporting_bucket/aide/$ssh_host_name/$report_file"
        echo "$aide_report" > "$report_file"
        aws s3 cp $report_file "$bucket_file" --quiet
        email_report=$( printf "%s\n\n%s" "$(awk '/^Start timestamp/,/Changed entries/ {print} /^End timestamp/ {print "\n" $0}' $report_file )" "Full report copied to $bucket_file" )
        rm $report_file

        mv /var/lib/aide/aide.db.gz /var/lib/aide/aide.db.packer.gz
        mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

        mailx -s "Aide Update <root@$ssh_host_name> /root/aide-update.bash" root <<< "$email_report"
      else
        mailx -s "Aide Update Error<root@$ssh_host_name> /root/aide-update.bash" root <<< "$aide_report"
      fi
runcmd:
  - |
    # Need this aide reports/updates
    r=$(ec2-metadata -z | awk '{print substr($2, 1, length($2)-1)}')
    i=$(ec2-metadata -i | awk '{print $2}')
    printf "export %q\nexport %q\nexport %q\n" "region=$r" "instance_id=$i" "reporting_bucket=${var.reporting_bucket}" > aws.sh
    printf "export %q\n" "ssh_host_name=$(aws ec2 describe-tags --filters Name=resource-id,Values=$i Name=key,Values=ssh_host_name --region=$r --output=text | cut -f5)" >> aws.sh
    sudo install -m 644 -o root -g root -D aws.sh /etc/profile.d/aws.sh
    rm aws.sh
    # password "set date" is yesterday so we'll pass a compliance scan the same day the servers were rebuilt
    cut -d: -f1 /etc/shadow | xargs -n1 chage --lastday $( date -d yesterday '+%F' )
    # chown and chmod all user directories after they've been created
    awk -F: '$3 >= 1000 && $1 != "nfsnobody" {print "chown -R " $3 ":" $4 " " $6 "\nchmod 700 " $6}' /etc/passwd | xargs --no-run-if-empty -0 sh -c
    # defer setting umask until after all of the yum installs have completed.
    sed -i -E -e '/umask 002/s/002/027/' /etc/profile /etc/bashrc
    sed -i -E -e '/umask 022/s/022/077/' /etc/profile /etc/bashrc
    at -M -f /root/aide-update.bash now +10 minutes
EOF

}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "reporting_bucket" {
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

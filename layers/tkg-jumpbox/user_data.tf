data "template_file" "tag_completion" {
  template = <<EOF
  write_files:
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - content: |
      #!/usr/bin/env bash
      set -eo pipefail
      exit_code=$1

      # grab last 5 lines from log | delete the last two lines | compress stdin -> stdout | base64 encode | flatten to a single line

      #cloud_init_output="$(tail -5 /var/log/cloud-init-output.log | head -n -2  | gzip -qc - | openssl enc -a -e | sed -zEe 's/\n/\\n/g')"
      #if [[ $(wc -c <<< $cloud_init_output) > 256 ]]; then
      #  cloud_init_output="$( echo "unable to display last 3 lines cloud-init since output > 256 bytes, please review logs for status" | gzip -qc - | openssl enc -a -e | sed -zEe 's/\n/\\n/g')"
      #fi

      export INSTANCE_ID=$(ec2-metadata -i | awk '{print $2}')
      export AWS_REGION=$(ec2-metadata -z | awk '{print substr($2, 1, length($2)-1)}')

      aws ec2 create-tags --resources $INSTANCE_ID --region $AWS_REGION --tags Key=testing,Value="this is a test!"

      [[ $exit_code == 0 ]] && STATUS=true || STATUS=false

      aws ec2 create-tags --resources $INSTANCE_ID --region $AWS_REGION --tags Key=cloud_init_done,Value=$STATUS
      aws ec2 create-tags --resources $INSTANCE_ID --region $AWS_REGION --tags Key=cloud_init_output,Value="$cloud_init_output"
      exit $exit_code
    path: /root/tagOnCompletion.sh
    permissions: '0750'
    owner: root:root

runcmd:
  - |
    function tagger() {
      /root/tagOnCompletion.sh $1
    }

    trap 'tagger $?' exit
EOF
}

data "template_file" "home_directory" {
  template = <<EOF
bootcmd:
  - |
    set -ex
    while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
    #old code won't mkfs an existing fs
    #if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

    # new code will always mkfs a volume to start fresh with the correct verisions.
    # we have to mount an external volume because the base image has partitioned FS
    mkfs -t ext4 /dev/sdf

    if mountpoint -q /home; then
      umount /home
      sed -i '/^\/dev\/vg0\/home/d' /etc/fstab
    fi
    mount -t ext4 -o 'defaults,nofail,nodev,comment=TF_user_data' /dev/sdf /home

mounts:
  - [ "/dev/sdf", "/home", "ext4", "defaults,nofail,nodev", "0", "2" ]

EOF
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.template_file.tag_completion.rendered
  }

//  part {
//    filename     = "config.cfg"
//    content_type = "text/cloud-config"
//    content      = data.template_file.home_directory.rendered
//    merge_type   = "list(append)+dict(no_replace,recurse_list)"
//  }

//  part {
//    filename     = "iptables.cfg"
//    content_type = "text/cloud-config"
//    content      = module.iptables_rules.iptables_user_data
//    merge_type   = "list(append)+dict(no_replace,recurse_list)"
//  }
//
//  part {
//    filename     = "dnsmasq.cfg"
//    content_type = "text/cloud-config"
//    content      = module.dnsmasq.dnsmasq_user_data
//    merge_type   = "list(append)+dict(no_replace,recurse_list)"
//  }
}

//resource "null_resource" "tkgjb_status" {
//  count = 1
//  triggers = {
//    instance_id = aws_instance.tkgjb.id
//  }
//
//  provisioner "local-exec" {
//    on_failure  = fail
//    interpreter = ["/bin/bash", "-c"]
//    command     = <<-EOF
//    #!/usr/bin/env bash
//    set -e
//    completed_tag="cloud_init_done"
//    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${aws_instance.tkgjb.id} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
//    echo "running $poll_tags"
//    tags="$($poll_tags)"
//    COUNTER=0
//    LOOP_LIMIT=10
//    while [[ "$tags" == "" ]] ; do
//      if [[ $COUNTER -eq $LOOP_LIMIT ]]; then
//        echo "timed out waiting for $completed_tag to be set"
//        exit 1
//      fi
//      if [[ $COUNTER -gt 0 ]]; then
//        echo "$completed_tag not set, sleeping for 10s"
//        sleep 10s
//      fi
//      tags="$($poll_tags)"
//      let COUNTER=COUNTER+1
//    done
//    echo "$completed_tag = $tags"
//
//    if cloud_init_message="$( aws ec2 describe-tags --filters Name=resource-id,Values=${aws_instance.tkgjb.id} Name=key,Values=cloud_init_output --output text --query Tags[*].Value )"; then
//      [[ ! -z $cloud_init_message ]] && echo -e "cloud_init_output: $( echo -ne "$cloud_init_message" | openssl enc -d -a | gunzip -qc - )"
//    fi
//
//    [[ $tags == false ]] && exit 1 || exit 0
//    EOF
//  }
//}

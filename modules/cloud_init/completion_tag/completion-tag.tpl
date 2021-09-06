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
      cloud_init_output="$(tail -5 /var/log/cloud-init-output.log | head -n -2  | gzip -qc - | openssl enc -a -e | sed -zEe 's/\n/\\n/g')"
      if [[ $(wc -c <<< $cloud_init_output) > 256 ]]; then
        cloud_init_output="$( echo "unable to display last 3 lines cloud-init since output > 256 bytes, please review logs for status" | gzip -qc - | openssl enc -a -e | sed -zEe 's/\n/\\n/g')"
      fi

      export INSTANCE_ID=$(ec2-metadata -i | awk '{print $2}')
      export AWS_REGION=$(ec2-metadata -z | awk '{print substr($2, 1, length($2)-1)}')

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

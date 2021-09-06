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

      export INSTANCE_ID=$(ec2metadata --instance-id)
      export AWS_REGION=$(ec2metadata --availability-zone | awk '{print substr($1, 1, length($1)-1)}')
      export GEM_PATH=/home/tempest-web/./tempest/web/vendor/bundle/ruby/2.6.0/

      [[ $exit_code == 0 ]] && STATUS=true || STATUS=false

      ruby -e "require 'aws-sdk-ec2'; Aws::EC2::Client.new().create_tags({resources:[ARGV[0],],tags:[{key: \"cloud_init_done\", value: ARGV[1],},],})" "$INSTANCE_ID" "$STATUS"
      ruby -e "require 'aws-sdk-ec2'; Aws::EC2::Client.new().create_tags({resources:[ARGV[0],],tags:[{key: \"cloud_init_output\", value: ARGV[1],},],})" "$INSTANCE_ID" "$cloud_init_output"
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

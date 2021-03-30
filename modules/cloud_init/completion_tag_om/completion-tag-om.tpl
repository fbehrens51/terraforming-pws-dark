#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - content: |
      #!/usr/bin/env bash
      set -ex
      echo "Running cloud-init status --wait > /dev/null"
      sudo cloud-init status --wait > /dev/null
      sudo cloud-init status --long
      TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      INSTANCE_ID=$(curl -H "X-aws-ec2 -$TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)
      AWSAZ=$(curl -H "X-aws-ec2 -$TOKEN" -v http://169.254.169.254/latest/meta-data/placement/availability-zone)
      AWSREGION=${AWSAZ::-1}
      export GEM_PATH=/home/tempest-web/./tempest/web/vendor/bundle/ruby/2.6.0/
      ruby -e "require 'aws-sdk-ec2'; client = Aws::EC2::Client.new(region: ARGV[0]); resp = client.create_tags({resources:[ARGV[1],],tags:[{key: \"cloud_init_done\", value: \"true\",},],})" $AWSREGION ${INSTANCE_ID}
    path: /root/tagOnCompletion.sh
    permissions: '0750'
    owner: root:root

runcmd:
  - |
    sleep 10
    sudo nohup /root/tagOnCompletion.sh &

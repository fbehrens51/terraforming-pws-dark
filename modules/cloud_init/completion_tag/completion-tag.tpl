#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - content: |
      echo "Running cloud-init status --wait > /dev/null"
      sudo cloud-init status --wait > /dev/null
      sudo cloud-init status --long
      TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
      INSTANCE_ID=$(curl -H "X-aws-ec2 -$TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)
      AWSAZ=$(curl -H "X-aws-ec2 -$TOKEN" -v http://169.254.169.254/latest/meta-data/placement/availability-zone)
      AWSREGION=${AWSAZ::-1}
      aws ec2 create-tags --resources ${INSTANCE_ID} --tags Key=cloud_init_done,Value=true --region $AWSREGION
    path: /root/tagOnCompletion.sh
    permissions: '0750'
    owner: root:root

runcmd:
  - nohup /root/tagOnCompletion.sh &

# create snapshot
VOLUME_ID=$1
AMI_NAME=$2
epoch_date=$(date +%s)

SNAPSHOTID=$(aws ec2 create-snapshot --volume-id $VOLUME_ID --output text --query "SnapshotId")
echo "Waiting for Snapshot ID: $SNAPSHOTID"

until aws ec2 wait snapshot-completed --snapshot-ids $SNAPSHOTID 2>/dev/null
do printf "\rsnapshot progress: %s" $progress;
    sleep 10
    progress=$(aws ec2 describe-snapshots --snapshot-ids $SNAPSHOTID --query "Snapshots[*].Progress" --output text)
done


aws ec2 register-image --name $AMI_NAME-$epoch_date --virtualization-type hvm --architecture "x86_64" --root-device-name "/dev/xvda" --block-device-mappings "[{\"DeviceName\": \"/dev/xvda\",\"Ebs\":{\"SnapshotId\":\"$SNAPSHOTID\"}}]" --ena-support

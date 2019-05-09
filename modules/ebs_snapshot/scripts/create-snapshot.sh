#!/usr/bin/env bash

volume_id=$1
snap_name_tag=$2

#tag_arg
snapshot_id=$(aws ec2 create-snapshot --volume ${volume_id} --query 'SnapshotId' --output text)
echo $snapshot_id
tag_cmd="aws ec2 create-tags --resources $snapshot_id --tags 'Key=Name,Value=\"$snap_name_tag\"'"
eval " $tag_cmd"

progress=$(aws ec2 describe-snapshots --snapshot-ids ${snapshot_id} --query "Snapshots[*].Progress" --output text)

echo "waiting for snapshot ${snapshot_id}"
printf "\rsnapshot progress: %s \r" ${progress};
#until aws ec2 wait snapshot-completed --snapshot-ids ${snapshot_id} 2>/dev/null
until [[ ${progress} == "100%" ]]
do
    printf "\rsnapshot progress: %s" ${progress};
    sleep 10
    progress=$(aws ec2 describe-snapshots --snapshot-ids ${snapshot_id} --query "Snapshots[*].Progress" --output text)
done

printf "\rcompleted ${snapshot_id}\r";


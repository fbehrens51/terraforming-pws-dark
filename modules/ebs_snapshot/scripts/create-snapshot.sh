#!/usr/bin/env bash

volume_id=$1
echo ${volume_id}

snapshot_id=$(aws ec2 create-snapshot --volume ${volume_id} --query 'SnapshotId' --output text)

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

printf "\rcompleted\r";


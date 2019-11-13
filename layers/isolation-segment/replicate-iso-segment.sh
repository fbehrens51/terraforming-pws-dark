#!/usr/bin/env bash

set -ex

S3_PATH=$1
ISO_SEG_NAME=$2
DESTINATION_PATH=$3

S3_BUCKET=$(dirname $S3_PATH)
S3_KEY=$(basename $S3_PATH)

echo $S3_PATH
echo $ISO_SEG_NAME

aws s3 cp s3://$S3_PATH .
replicator --name "$ISO_SEG_NAME" --path $S3_KEY --output $DESTINATION_PATH
aws s3 cp $DESTINATION_PATH s3://$S3_BUCKET/

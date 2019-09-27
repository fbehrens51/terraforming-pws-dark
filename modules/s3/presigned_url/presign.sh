#!/bin/bash
set -ex

eval "$(jq -r '@sh "BUCKET_NAME=\(.bucket_name) OBJECT_PREFIX=\(.object_prefix)"')"
object_key=$(aws s3api list-objects-v2 --bucket pws-dark-ci-transfer --prefix $OBJECT_PREFIX --query "reverse(sort_by(Contents, &LastModified))[0].Key"|jq . -r)
presigned_url=$(aws s3 presign s3://$BUCKET_NAME/$object_key)
jq -n --arg url "$presigned_url" '{"url": $url}'

#!/bin/bash
set -e


eval "$(jq -r '@sh "BUCKET_NAME=\(.bucket_name) OBJECT_KEY=\(.object_key)"')"
presigned_url=$(aws s3 presign s3://$BUCKET_NAME/$OBJECT_KEY)
jq -n --arg url "$presigned_url" '{"url": $url}'

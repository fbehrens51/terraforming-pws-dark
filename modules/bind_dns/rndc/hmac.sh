#!/bin/bash
set -e

eval "$(jq -r '@sh "STRING=\(.string) SECRET=\(.secret)"')"
HMAC=$(echo -n $STRING | openssl dgst -md5 -hmac $SECRET -binary | base64)
jq -n --arg hmac "$HMAC" '{"key": $hmac}'

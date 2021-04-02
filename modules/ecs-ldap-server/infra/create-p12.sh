#!/usr/bin/env bash

set -e

input=$(cat)

cd "$(mktemp -d)"

echo "$input" | jq -r .pem  > cert.pem
echo "$input" | jq -r .key  > key.pem
passphrase=$(echo "$input" | jq -r .passphrase)

openssl pkcs12 -export \
        -passin pass:"$passphrase" \
        -passout pass:"$passphrase" \
        -in cert.pem \
        -inkey key.pem | base64 | jq --slurp -R '{p12: .}'

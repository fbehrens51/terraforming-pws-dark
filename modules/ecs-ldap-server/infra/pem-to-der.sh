#!/usr/bin/env bash

jq -r .pem |
    openssl x509 -inform pem -outform der |
    base64 |
    jq --slurp -R '{der: .}'

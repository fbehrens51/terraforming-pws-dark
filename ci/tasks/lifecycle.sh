#!/bin/bash -e

export AWS_DEFAULT_REGION=${region}
export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}

pushd ${env_path} > /dev/null

  terraform init

  trap 'terraform destroy -force; exit' EXIT

  terraform validate

  terraform plan -out=plan

  TF_LOG=TRACE TF_LOG_PATH=tf-logs.txt terraform apply plan

  terraform destroy -force

popd > /dev/null
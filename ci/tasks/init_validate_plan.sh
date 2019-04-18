#!/bin/bash -e

export AWS_DEFAULT_REGION=${region}
export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}

pushd ${env_path} > /dev/null

  terraform init

  trap 'terraform destroy -force; exit' EXIT

  terraform validate

  terraform plan

popd > /dev/null
#!/usr/bin/env bash

HEADER_FOOTER="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
set -e

#subnet_id to use for importer instance
SUBNET_ID=$1

export TF_VAR_subnet_id=${SUBNET_ID}

echo ${HEADER_FOOTER}
echo "Create vm_importer instance, upload img file from s3, extract to volume, and snapshot"
echo ${HEADER_FOOTER}

pushd ./../mjb-image/import/

terraform init
terraform apply -auto-approve
VOLUME_ID=$(terraform output volume_id)

export TF_VAR_volume_id=${VOLUME_ID}



echo ${HEADER_FOOTER}
echo "Create AMI from volume snapshot"
echo ${HEADER_FOOTER}
pushd ./../export-to-ami/

terraform init
terraform apply -auto-approve
#Not currently used, but may want to pass it through eventually
AMI_ID=$(terraform output ami_id)

popd
#destroy importer vm and volume now that AMI has been created
echo ${HEADER_FOOTER}
echo "Cleanup (destroy) vm_importer instance and related resources"
echo ${HEADER_FOOTER}

terraform init
terraform destroy -auto-approve
popd

echo ${HEADER_FOOTER}
echo "Launch MJB using created AMI"
echo ${HEADER_FOOTER}

pushd ./../mjb-launch/
terraform init
terraform apply -auto-approve




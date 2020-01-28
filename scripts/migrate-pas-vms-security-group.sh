#!/usr/bin/env bash

VMS_SECURITY_GROUP_ID=$(terragrunt output vms_security_group_id)
BASTION_PRIVATE_IP=$(terragrunt output bastion_private_ip --terragrunt-working-dir ../bastion)
PAS_VPC_CIDR=$(terragrunt state show data.aws_vpc.pas_vpc | grep 'cidr_block ' | awk '{print $3}' | jq -r .)

echo 'VMS_SECURITY_GROUP_ID: ' $VMS_SECURITY_GROUP_ID
echo 'BASTION_PRIVATE_IP: ' $BASTION_PRIVATE_IP
echo 'PAS_VPC_CIDR: ' $PAS_VPC_CIDR

terragrunt import module.infra.aws_security_group_rule.ingress_from_bastion ${VMS_SECURITY_GROUP_ID}_ingress_tcp_22_22_${BASTION_PRIVATE_IP}/32

terragrunt import module.infra.aws_security_group_rule.ingress_from_pas_vpc ${VMS_SECURITY_GROUP_ID}_ingress_all_0_65536_${PAS_VPC_CIDR}

terragrunt import module.infra.aws_security_group_rule.ingress_from_self ${VMS_SECURITY_GROUP_ID}_ingress_all_0_65536_self

terragrunt import module.infra.aws_security_group_rule.egress_anywhere ${VMS_SECURITY_GROUP_ID}_egress_all_0_65536_0.0.0.0/0

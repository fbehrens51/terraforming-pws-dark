---
credentials:
- name: /concourse/compliance/opsman_ssh_private_key
  type: ssh
  value:
    private_key: |
      ${indent(6, BOT_KEY_PEM)}
- name: /concourse/compliance/opsman_ssh_target
  type: value
  value: ${OM_PRIVATE_IP}
- name: /concourse/compliance/control_plane_opsman_ssh_target
  type: value
  value: ${CP_OM_PRIVATE_IP}
- name: /concourse/main/opsman_ssh_private_key
  type: ssh
  value:
    private_key: |
      ${indent(6, BOT_KEY_PEM)}
- name: /concourse/main/opsman_ssh_target
  type: value
  value: ${OM_PRIVATE_IP}
- name: /concourse/main/control_plane_opsman_ssh_target
  type: value
  value: ${CP_OM_PRIVATE_IP}
- name: /concourse/compliance/mirror_bucket
  type: value
  value: ${MIRROR_BUCKET}
- name: /concourse/compliance/s3_endpoint
  type: value
  value: ${S3_ENDPOINT}
- name: /concourse/compliance/region
  type: value
  value: ${REGION}
- name: /concourse/compliance/public_bucket
  type: value
  value: ${PUBLIC_BUCKET}
- name: /concourse/compliance/ca_cert_bucket
  type: value
  value: ${CA_CERT_BUCKET}
- name: /concourse/compliance/reporting_bucket
  type: value
  value: ${REPORTING_BUCKET}
- name: /concourse/compliance/env_name
  type: value
  value: ${ENV_NAME}
- name: /concourse/main/ca_cert_bucket
  type: value
  value: ${CA_CERT_BUCKET}
- name: /concourse/main/pas_backup_bucket
  type: value
  value: ${PAS_BACKUP_BUCKET}
- name: /concourse/main/region
  type: value
  value: ${REGION}
- name: /concourse/main/public_bucket
  type: value
  value: ${PUBLIC_BUCKET}
- name: /concourse/main/s3_endpoint
  type: value
  value: ${S3_ENDPOINT}
- name: /concourse/main/mirror_bucket
  type: value
  value: ${MIRROR_BUCKET}
- name: /concourse/main/kms_key_id
  type: value
  value: ${KMS_KEY_ID}
- name: /concourse/main/env_name
  type: value
  value: ${ENV_NAME}
- name: /concourse/main/root_ca_cert_file
  type: value
  value: |
      ${indent(6, ROOT_CA_CERT_FILE)}
- name: /concourse/main/iaas_ca_cert_file
  type: value
  value: |
      ${indent(6, IAAS_CA_CERT_FILE)}
- name: /concourse/main/ops_manager_bucket
  type: value
  value: ${OPS_MANAGER_BUCKET}
- name: /concourse/main/smtp_domain
  type: value
  value: ${SMTP_DOMAIN}
- name: /concourse/main/smtp_from
  type: value
  value: ${SMTP_FROM}
- name: /concourse/main/smtp_to
  type: json
  value:
    - ${SMTP_TO}
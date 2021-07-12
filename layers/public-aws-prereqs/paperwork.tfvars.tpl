root_domain = "${root_domain}"

smtp_from = "${smtp_from}"

smtp_to = "${smtp_to}"

pas_vpc_id = "${pas_vpc_id}"

bastion_vpc_id = "${bastion_vpc_id}"

es_vpc_id = "${es_vpc_id}"

cp_vpc_id = "${cp_vpc_id}"

iso_vpc_ids = ["${iso_vpc_id}"]

fluentd_role_name = "${fluentd_role_name}"

isse_role_name = "${isse_role_name}"

ent_tech_read_role_name = "${ent_tech_read_role_name}"

instance_tagger_role_name = "${instance_tagger_role_name}"

director_role_name = "${director_role_name}"

om_role_name = "${om_role_name}"

bosh_role_name = "${bosh_role_name}"

sjb_role_name = "${sjb_role_name}"

concourse_role_name = "${concourse_role_name}"

bootstrap_role_name = "${bootstrap_role_name}"

foundation_role_name = "${foundation_role_name}"

tsdb_role_name = "${tsdb_role_name}"

bucket_role_name = "${bucket_role_name}"

platform_automation_engine_worker_role_name = "${platform_automation_engine_worker_role_name}"

system_domain = "${system_domain}"

apps_domain = "${apps_domain}"

ldap_basedn = "${ldap_basedn}"

ldap_dn = "${ldap_dn}"

ldap_host = "${ldap_host}"

ldap_port = "${ldap_port}"

ldap_role_attr = "${ldap_role_attr}"

ldap_password_s3_path = "${ldap_password_s3_path}"

cert_bucket = "${cert_bucket}"

root_ca_cert_s3_path = "${root_ca_cert_s3_path}"

router_trusted_ca_certs_s3_path = "${router_trusted_ca_certs_s3_path}"

trusted_ca_certs_s3_path = "${trusted_ca_certs_s3_path}"

additional_trusted_ca_certs_s3_path = "${additional_trusted_ca_certs_s3_path}"

rds_ca_cert_s3_path = "${rds_ca_cert_s3_path}"

smtp_relay_ca_cert_s3_path = "${smtp_relay_ca_cert_s3_path}"

smtp_relay_password_s3_path = "${smtp_relay_password_s3_path}"

grafana_server_cert_s3_path = "${grafana_server_cert_s3_path}"

grafana_server_key_s3_path = "${grafana_server_key_s3_path}"

router_server_cert_s3_path = "${router_server_cert_s3_path}"

router_server_key_s3_path = "${router_server_key_s3_path}"

uaa_server_cert_s3_path = "${uaa_server_cert_s3_path}"

uaa_server_key_s3_path = "${uaa_server_key_s3_path}"

ldap_ca_cert_s3_path = "${ldap_ca_cert_s3_path}"

ldap_client_cert_s3_path = "${ldap_client_cert_s3_path}"

ldap_client_key_s3_path = "${ldap_client_key_s3_path}"

control_plane_star_server_cert_s3_path = "${control_plane_star_server_cert_s3_path}"

control_plane_star_server_key_s3_path = "${control_plane_star_server_key_s3_path}"

om_server_cert_s3_path = "${om_server_cert_s3_path}"

om_server_key_s3_path = "${om_server_key_s3_path}"

fluentd_server_cert_s3_path = "${fluentd_server_cert_s3_path}"

fluentd_server_key_s3_path = "${fluentd_server_key_s3_path}"

smtp_server_cert_s3_path = "${smtp_server_cert_s3_path}"

smtp_server_key_s3_path = "${smtp_server_key_s3_path}"

portal_smoke_test_cert_s3_path = "${portal_smoke_test_cert_s3_path}"

portal_smoke_test_key_s3_path = "${portal_smoke_test_key_s3_path}"

vanity_server_cert_s3_path = "${vanity_server_cert_s3_path}"

vanity_server_key_s3_path = "${vanity_server_key_s3_path}"

// We force this to us-east-1 because combine only supports us-east-1.
// Using a different region for log forwarding would prevent using the CAP
// authentication mechanism.
log_forwarder_region = "us-east-1"

cap_url = "https://combine-1-elb-tap-e-770a8babaa78d696.elb.us-east-1.amazonaws.com"

cap_root_ca_s3_path = "${cap_root_ca_s3_path}"

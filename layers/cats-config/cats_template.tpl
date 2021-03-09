
{
  "api": "api.${system_fqdn}",
  "apps_domain": "${apps_fqdn}",
  "admin_user": "admin",
  "admin_password": "${admin_password}",
  "artifacts_directory": "logs",
  "skip_ssl_validation": true,
  "timeout_scale": 2,
  "use_http": false,
  "use_log_cache": false,
  "include_apps": true,
  "include_container_networking": true,
  "credhub_mode": "assisted",
  "credhub_client": "credhub_admin_client",
  "credhub_secret": "${credhub_password}",
  "include_deployments": true,
  "include_detect": true,
  "include_docker": false,
  "include_app_syslog_tcp": false,
  "include_internet_dependent": false,
  "include_internetless": false,
  "include_isolation_segments": true,
  "include_logging_isolation_segments": false,
  "include_private_docker_registry": false,
  "include_route_services": true,
  "include_routing": true,
  "include_tcp_routing": false,
  "include_routing_isolation_segments": false,
  "include_security_groups": false,
  "include_service_discovery": false,
  "include_services": false,
  "include_service_instance_sharing": false,
  "include_ssh": false,
  "include_sso": false,
  "include_tasks": true,
  "include_v3": true,
  "include_zipkin": true,
  "include_credhub": false,
  "include_volume_services": false,
  "isolation_segment_name": "customer-a",
  "stacks": [
    "cflinuxfs3"
  ],
  "java_buildpack_name": "java_buildpack_offline",
  "require_proxied_app_traffic": true
}
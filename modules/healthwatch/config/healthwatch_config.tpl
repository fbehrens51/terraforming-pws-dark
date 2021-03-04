product-name: p-healthwatch2
product-properties:
  .grafana.additional_cipher:
    value: ${grafana_additional_cipher_suites}
  .grafana.enable_indipro_integration:
    value: true
  .grafana.enable_login_form:
    value: true
  .grafana.enable_mysql:
    value: false
  .grafana.enable_rabbitmq:
    value: false
  .grafana.root_url:
    value: ${grafana_root_url}
  .grafana.ssl_ca_certificate:
    value: |-
      ${indent(6, chomp(root_ca_cert))}
  .grafana.ssl_certificates:
    value:
      cert_pem: |
        ${indent(8, chomp(grafana_server_cert))}
      private_key_pem: |
        ${indent(8, chomp(grafana_server_key))}
  .properties.canary_exporter_targets:
    value:
    - address: ${canary_url}
  .properties.dashboard_discovery:
    selected_option: dynamic
    value: dynamic
  .properties.enable_telemetry:
    value: false
  .properties.grafana_authentication:
    selected_option: uaa
    value: uaa
  .properties.grafana_authentication.uaa.client_id:
    value: grafana
  .properties.grafana_authentication.uaa.client_secret:
    value:
      secret: ${grafana_uaa_client_secret}
  .properties.grafana_authentication.uaa.root_url:
    value: ${uaa_url}
  .properties.grafana_authentication.uaa.tls_skip_verify_insecure:
    value: false
  .properties.grafana_proxy:
    selected_option: disabled
    value: disabled
  .properties.opsman_url:
    value: ${ops_canary_url}
  .properties.pks_cluster_discovery:
    selected_option: disabled
    value: disabled
  .properties.scrape_configs:
    value:
    # We use the grafana_server_cert/key for the node_exporters on each VM
    - ca: |
        ${indent(8, chomp(root_ca_cert))}
      # We are only enabling TLS for the encryption. Each host has a different name,
      # and the cert will not match them. The list is also dynamic, so we can't
      # pre-allocate a cert with all the names.
      insecure_skip_verify: true
      scrape_job: |
        job_name: 'ec2'
        scheme: https
        ec2_sd_configs:
        - region: ${region}
          port: 9100
        relabel_configs:
        # Only monitor instances with a MetricsKey tag matchine mine
        - source_labels: [__meta_ec2_tag_MetricsKey]
          regex: ${metrics_key}
          action: keep
        - source_labels: [__meta_ec2_tag_Name]
          target_label: name_tag
        - source_labels: [__meta_ec2_availability_zone]
          target_label: availability_zone
        - source_labels: [__meta_ec2_instance_id]
          target_label: instance_id
      server_name: null
      tls_certificates: {}
    - ca: |
        ${indent(8, chomp(root_ca_cert))}
      insecure_skip_verify: false
      scrape_job: |-
        job_name: 'fluentd'
        metrics_path: /aggregated_metrics
        static_configs:
        - targets:
          - ${fluentd_root_url}
      server_name: null
      tls_certificates: {}
  .properties.smtp:
%{ if smtp_enabled != "true" ~}
    selected_option: disabled
    value: disabled
%{ else ~}
    selected_option: enabled
    value: enabled
  .properties.smtp.enabled.from_address:
    value: ${smtp_from}
  .properties.smtp.enabled.host:
    value: ${smtp_host}
  .properties.smtp.enabled.password:
    value:
      secret: ${smtp_password}
  .properties.smtp.enabled.port:
    value: ${smtp_port}
  .properties.smtp.enabled.skip_verify:
    value: false
  .properties.smtp.enabled.tls_credentials:
    value:
      cert_pem: |
        ${indent(8, chomp(grafana_server_cert))}
      private_key_pem: |
        ${indent(8, chomp(grafana_server_key))}
  .properties.smtp.enabled.user:
    value: ${smtp_user}
%{ endif ~}
  .tsdb.alerting_rules:
    value: |-
      groups:
        ##### BEGIN FOUNDATION ALERTING RULES #####
        - name: BOSHDirectorHealth
          rules:
            - alert: BOSHDirectorStatus
              expr: 'increase(bosh_sli_failures_total{scrape_instance_group="bosh-health-exporter"}[20m]) > 0'
              for: 20m
              annotations:
                summary: "A BOSH Director is down"
                description: |
                  Losing the BOSH Director does not significantly impact the experience of Tanzu Application Service end users. However, this issue means a loss of resiliency for BOSH-managed VMs.

                  Troubleshooting Steps:
                  SSH into the `bosh-health-exporter` VM in the "Healthwatch Exporter" deployment, and view logs to find out why the BOSH Director is failing.
        - name: CertificateExpiration
          rules:
            - alert: ExpiringCertificate
              expr: "ssl_certificate_expiry_seconds < 2592000"
              for: 5m
              annotations:
                summary: "A certificate is expiring"
                description: |
                  At least one certificate ({{ $labels.display_name }}) on your foundation is going to expire within 30 days.
        - name: OpsManagerHealth
          rules:
            - alert: OpsManagerStatus
              expr: 'probe_success{instance="<OPS_MANAGER_URL>"} <= 0'
              for: 10m
              annotations:
                summary: "The Ops Manager health check failed"
                description: |
                  Issues with Ops Manager health should have no direct end user impacts, however it can can impact an operatorâ€™s ability to perform an upgrade or to rescale the Tanzu Application Service platform when necessary.
        ##### END FOUNDATION ALERTING RULES #####

        ##### BEGIN TAS ALERTING RULES #####
        - name: TanzuApplicationServiceSLOs
          rules:
            - alert: TanzuSLOCFPushErrorBudget
              expr: '( (1 - (rate(pas_sli_task_failures_total{task="push"}[28d]) / rate(pas_sli_task_runs_total{task="push"}[28d]) ) ) - 0.99) * (28 * 24 * 60) <= 0'
              for: 15m
              annotations:
                summary: "The `cf_push` command is unresponsive"
                description: |
                  This alert fires when the error budget reaches zero.

                  This commonly occurs when:
                  - Diego is under-scaled
                  - UAA is unresponsive
                  - Cloud Controller is unresponsive

                  Check the status of these components in order to diagnose the issue.
            - alert: TanzuSLOCFPushAvailability
              expr: 'rate(pas_sli_task_failures_total{task="push"}[5m:15s]) * 300 > 0'
              for: 10m
              annotations:
                summary: "The `cf_push` command is unresponsive"
                description: |
                  This alert fires when the command has been unresponsive for 10 minutes.

                  This commonly occurs when:
                  - Diego is under-scaled
                  - UAA is unresponsive
                  - Cloud Controller is unresponsive

                  Check the status of these components in order to diagnose the issue.
            - alert: TanzuSLOCanaryAppErrorBudget
              expr: "( (avg_over_time(probe_success[28d]) - 0.999) * (28 * 24 * 60) ) <= 0"
              for: 10m
              annotations:
                summary: "Your Error Budget for your Canary URLs is below zero"
                description: |
                  This alert fires when your error budget for your Canary URLs is below zero.
                  If your Canary URLs are representative of other running applications, this could indicate that your end users are affected.

                  Recommended troubleshooting steps:
                  Check to see if your canary app(s) are running. Then check your foundation's networking, capacity, and VM health.
            - alert: TanzuSLOCanaryAppAvailability
              expr: "avg_over_time(probe_success[5m]) < 1"
              for: 1m
              annotations:
                summary: "Your Canary URL ({{ $labels.instance }}) is unresponsive"
                description: |
                  The Canary URL ({{ $labels.instance }}) has been unresponsive for at least 5 minutes.
                  If your Canary URL is representative of other running applications, this could indicate that your end users are affected.

                  Recommended troubleshooting steps:
                  Check to see if your canary app(s) are running. Then check your foundation's networking, capacity, and VM health.
        - name: TASCLIHealth
          rules:
            - alert: TASCLICommandStatus
              expr: "increase(pas_sli_task_failures_total[10m]) > 0"
              for: 10m
              annotations:
                summary: "Healthwatch Tanzu Application Service CLI tests are failing"
                description: |
                  One or more CLI tests have been failing for at least 10 minutes.
                  App Smoke Tests run every 5-minutes. When running HA, multiple smoke tests may run in the given 5-minutes. These tests are intended to give Platform Operators confidence that Application Developers can successfully interact with and manage applications on the platform.
                  Note: smoke tests will report a failure if any task (e.g. `push`, `login`) takes more than 5 minutes to complete.

                  Troubleshooting Steps:
                  If a failure occurs, attempt to use the failed CLI command in a terminal to see why it is failing.
        - name: TASDiego
          rules:
            - alert: TASDiegoMemoryUsed
              expr: 'label_replace( (sum by (placement_tag) (CapacityTotalMemory) - sum by (placement_tag) (CapacityRemainingMemory) ) / sum by (placement_tag) (CapacityTotalMemory), "placement_tag", "cf", "placement_tag", "") > .65'
              for: 10m
              annotations:
                summary: "Available memory for Diego Cells is running low"
                description: |
                  You have exceeded 65% of your available Diego Cell memory capacity for ({{ $labels.placement_tag }}) for at least 10 minutes.
                  Low memory can prevent app scaling and new deployments. The overall sum of capacity can indicate that you need to scale the platform. It is recommended that you have enough memory available to suffer a possible failure of an entire availability zone (AZ). If following the best practice guidance of three AZs, your % available memory should always be at least 35%.

                  Troubleshooting Steps:
                  Assign more resources to the cells or assign more cells by scaling Diego cells in the Resource Config pane of the Tanzu Application Service tile.
            - alert: TASDiegoDiskUsed
              expr: 'label_replace( (sum by (placement_tag) (CapacityTotalDisk) - sum by (placement_tag) (CapacityRemainingDisk) ) / sum by (placement_tag) (CapacityTotalDisk), "placement_tag", "cf", "placement_tag", "") > .65'
              for: 10m
              annotations:
                summary: "Available disk for Diego Cells is running low"
                description: |
                  You have exceeded 65% of your available Diego Cell disk capacity for ({{ $labels.placement_tag }}) for at least 10 minutes.
                  Low disk capacity can prevent app scaling and new deployments. The overall sum of capacity can indicate that you need to scale the platform. It is recommended that you have enough disk available to suffer a possible failure of an entire availability zone (AZ). If following the best practice guidance of three AZs, your % available disk should always be at least 35%.

                  Troubleshooting Steps:
                  Assign more resources to the cells or assign more cells by scaling Diego cells in the Resource Config pane of the Tanzu Application Service tile.
        - name: TASMySQLHealth
          rules:
            - alert: TASMySQLStatus
              expr: "_mysql_available <= 0"
              for: 10m
              annotations:
                summary: "The Tanzu Application Service MySQL database is not responding"
                description: |
                  The MySQL database is used for persistent data storage by several Tanzu Application Service components. Note that this is the SQL database used by system components, not the MySQL service used by applications running on the platform.
                  Tanzu Application Service components that use system databases include the Cloud Controller, Diego Brain, Gorouter, and the User Authorization and Authentication (UAA) server.

                  Troubleshooting Steps:
                  Run mysql-diag and check the MySQL Server logs for errors.
        - name: TASRouter
          rules:
            - alert: TASRouterHealth
              expr: 'system_healthy{exported_job="router", origin="bosh-system-metrics-forwarder"} <= 0 OR system_healthy{exported_job="router", origin="system_metrics_agent"} <= 0'
              for: 10m
              annotations:
                summary: "The Tanzu Application Service Router is down"
                description: |
                  The Tanzu Application Service Router being down prevents users from interacting with applications and services on the platform.

                  Troubleshooting Steps:
                  Review detailed Tanzu Application Service Router metrics and logs for details on the cause of the error.
            - alert: TASRouterCPUUtilization
              expr: 'system_cpu_user{exported_job="router", origin="bosh-system-metrics-forwarder"} >= 80 OR system_cpu_user{exported_job="router", origin="system_metrics_agent"} >= 80'
              for: 5m
              annotations:
                summary: "The Tanzu Application Service Router is experiencing average CPU utilization above 80%"
                description: |
                  High CPU utilization of the Gorouter VMs can increase latency and cause throughput, or requests per/second, to level-off. It is recommended to keep the CPU utilization within a maximum range of 60-70% for best Gorouter performance.

                  Troubleshooting Steps:
                  Resolve high utilization by scaling the Gorouters horizontally, or vertically by editing the Router VM in the Resource Config pane of the Tanzu Application Service tile.
            - alert: TASRouterFileDescriptors
              expr: "file_descriptors >= 90000"
              for: 5m
              annotations:
                summary: "A Tanzu Application Service Router job has exceeded 90,000 file descriptors over the past 5 minutes"
                description: |
                  The Tanzu Application Service Router on index ({{ $labels.index }}) has exceeded 90,000 file descriptors over the past 5 minutes.

                  File Descriptors are an indication of an impending issue with the GoRouter. Each incoming request to the router consumes 2 file descriptors. Without the proper mitigations, it could be possible for an unresponsive application to eventually exhaust the file descriptors in GoRouter, starving routes from other applications running on Tanzu Application Service.

                  Troubleshooting steps:
                  (1) Identify which app(s) are requesting excessive connections and resolve the impacting issues with these applications.
                  (2) If above recommended mitigations have not already been taken, do so.
                  (3) Consider adding more GoRouter VM resources to increase total available file descriptors.
        - name: TASUAA
          rules:
            - alert: TASUAAHealth
              expr: 'system_healthy{exported_job="uaa", origin="bosh-system-metrics-forwarder"} <= 0 OR system_healthy{exported_job="uaa", origin="system_metrics_agent"} <= 0'
              for: 10m
              annotations:
                summary: "A UAA VM has been unhealthy for 10 minutes"
                description: |
                  The Tanzu Application Service UAA on index ({{ $labels.index }}) has been unhealthy for 10 minutes.
                  If UAA is down, developers and operators cannot authenticate to access the platform.

                  Troubleshooting steps:
                  - Scale the UAA VMs in BOSH
                  - See the [UAA Documentation](https://docs.run.pivotal.io/concepts/architecture/uaa.html) for more details and troubleshooting ideas.
        # APPLY THIS IF THE USAGE SERVICE IS DESIRED/INSTALLED
        - name: TASUsageService
          rules:
            - alert: TASUsageServiceEventProcessingLag
              expr: 'sum(usage_service_app_usage_event_cc_lag_seconds) by (deployment) >= 172800'
              for: 5m
              annotations:
                summary: "Usage Service has failed to fetch Events from Cloud Controller (CAPI) for the last 48 hours for the deployment ({{ $labels.deployment }}."
                description: |
                  This is typically caused when Usage Service is running correctly, but can't reach CAPI. Common issues are Usage Service can not authenticate, Cloud Controller is in a bad state or the network settings are incorrectly set up.

                  Troubleshooting Steps:
                  - Check CAPI - Try `cf curl /v2/app_usage_events`. The response should be 200 with recent events as the payload.
                  - Check UAA - Make sure the Usage Service can authenticate with CAPI.
                  - Check the network settings.

                  * If the Usage Service fails to fetch events for 7 or more days, reach out to support.
                  **Data loss can occur if the Usage Service fails to fetch events for more than 29 days. **
            - alert: TASUsageServiceEventFetchingStatus
              expr: 'sum(usage_service_app_usage_event_fetcher_job_exit_code) by (deployment) >= 1'
              for: 6h
              annotations:
                summary: "Usage Service Event Fetching is failing for the deployment ({{ $labels.deployment }}."
                description: |
                  Typically, this means the Usage Service is healthy, but CAPI is not returning the information that is being requested. Historically, this has happened either due to network failures, or the UAA component not authenticating the Usage Service application successfully.

                  Troubleshooting steps:
                  - Check to see if you are able to query CAPI for /v2/app_usage_events and /v2/service_usage_events using the `cf curl` command. A failure would indicate there is a problem outside of the Usage Service application affecting the health of the foundation.
                  - Check to see if UAA is working correctly.

                  * If the Usage Service Event Fetching is failing for more than 7 days, reach out to support immediately.
                  **Data loss can occur if Event Fetching fails for more than 29 days.**
        ##### END TAS ALERTING RULES #####

        ##### BEGIN HEALTHWATCH ALERTING RULES #####
        - name: HealthwatchTASSLOs
          rules:
            - alert: HealthwatchTASFunctionalExporter
              expr: 'service_up{service="pas-sli-exporter"} < 1'
              for: 10m
              annotations:
                summary: "The Healthwatch Tanzu Application Service Functional Exporter is down"
                description: |
                  The Healthwatch Tanzu Application Service Functional Exporter has been down for 10 minutes.
            - alert: HealthwatchTASCounterExporter
              expr: 'service_up{service="pas-exporter-counter"} < 1'
              for: 10m
              annotations:
                summary: "The Healthwatch Tanzu Application Service Counter Exporter is down"
                description: |
                  The Healthwatch Tanzu Application Service Counter Exporter has been down for 10 minutes.
            - alert: HealthwatchTASGaugeExporter
              expr: 'service_up{service="pas-exporter-gauge"} < 1'
              for: 10m
              annotations:
                summary: "The Healthwatch Tanzu Application Service Gauge Exporter is down"
                description: |
                  The Healthwatch Tanzu Application Service Gauge Exporter has been down for 10 minutes.
            - alert: HealthwatchTASTimerExporter
              expr: 'service_up{service="pas-exporter-timer"} < 1'
              for: 10m
              annotations:
                summary: "The Healthwatch Tanzu Application Service Timer Exporter is down"
                description: |
                  The Healthwatch Tanzu Application Service Timer Exporter has been down for 10 minutes.
        ##### END HEALTHWATCH ALERTING RULES #####
%{ if smtp_enabled == "true" ~}
  .tsdb.alerting_email_receiver_config:
    value:
    - auth_password:
        secret: ${smtp_password}
      auth_secret: {}
      ca: null
      insecure_skip_verify: false
      receiver_config: |-
        send_resolved: true
        to: ${email_addresses}
        from: ${smtp_from}
        auth_username: ${smtp_user}
        smarthost: ${smtp_host}:${smtp_port}
      receiver_name: PWS Dark Alerts
      server_name: null
      tls_certificates: {}
%{ endif ~}
%{ if slack_enabled == "true" ~}
  .tsdb.alerting_slack_receiver_config:
    value:
    - basic_auth: {}
      bearer_token: {}
      ca: null
      insecure_skip_verify: false
      receiver_config: |
        send_resolved: true
        channel: pws-dark-notifications
      receiver_name: PWS Dark Alerts
      server_name: null
      slack_api_url:
        secret: ${slack_webhook}
      tls_certificates: {}
%{ endif ~}
  .tsdb.canary_exporter_port:
    value: 9115
  .tsdb.disk_chunk_size:
    value: 6144
  .tsdb.memory_chunk_size:
    value: 4096
  .tsdb.routing_rules:
    value: |-
      route:
        receiver: PWS Dark Alerts
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
        group_by: [alertname]
  .tsdb.scrape_interval:
    value: 15s
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
  ${hw_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  grafana:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions:
    - tsdb_instance_profile
    elb_names:
    - ${grafana_elb_id}
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pxc:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pxc-proxy:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  tsdb:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - tsdb_instance_profile
    elb_names: []
    instance_type:
      id: r5.large
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  smoke-test:
    post-deploy-state: true
  update-admin-password:
    post-deploy-state: true
syslog-properties:
  address: ${syslog_host}
  custom_rsyslog_configuration: null
  enabled: true
  forward_debug_logs: false
  permitted_peer: ${syslog_host}
  port: ${syslog_port}
  queue_size: null
  ssl_ca_certificate: |
    ${indent(4, chomp(syslog_ca_cert))}
  tls_enabled: true
  transport_protocol: tcp

product-name: splunk-nozzle
product-properties:
  .properties.add_app_info:
    value: false
  .properties.allow_paid_service_plans:
    value: true
  .properties.api_endpoint:
    value: ${api_endpoint}
  .properties.api_password:
    value:
      secret: ((api_password))
  .properties.api_user:
    value: splunk-firehose
  .properties.app_cache_invalidate_ttl:
    value: 0s
  .properties.app_limits:
    value: 0
  .properties.apply_open_security_group:
    value: true
  .properties.consumer_queue_size:
    value: 10000
  .properties.enable_event_tracing:
    value: false
  .properties.events:
    value:
    - HttpStartStop
    - LogMessage
    - ValueMetric
    - CounterEvent
    - Error
    - ContainerMetric
  .properties.firehose_keep_alive:
    value: 25s
  .properties.flush_interval:
    value: 5s
  .properties.hec_batch_size:
    value: 100
  .properties.hec_retries:
    value: 5
  .properties.hec_workers:
    value: 8
  .properties.ignore_missing_app:
    value: true
  .properties.missing_app_cache_invalidate_ttl:
    value: 0s
  .properties.nozzle_memory:
    value: 256M
  .properties.org:
    value: splunk-nozzle-org
  .properties.org_space_cache_invalidate_ttl:
    value: 72h
  .properties.scale_out_nozzle:
    value: 2
  .properties.skip_ssl_validation_cf:
    value: false
  .properties.skip_ssl_validation_splunk:
    value: true
  .properties.space:
    value: splunk-nozzle-space
  .properties.splunk_host:
    value: ${splunk_url}
  .properties.splunk_index:
    value: main
  .properties.splunk_token:
    value:
      secret: ${splunk_token}
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
  - name: ${availability_zones}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  delete-all:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
  deploy-all:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
errand-config:
  delete-all:
    pre-delete-state: true
  deploy-all:
    post-deploy-state: true
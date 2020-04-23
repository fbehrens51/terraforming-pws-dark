<source>
  @type syslog
  port ${syslog_port}
  bind 0.0.0.0
  tag syslog
  emit_unmatched_lines true
  <transport tls>
    ca_path /etc/td-agent/ca.pem
    cert_path /etc/td-agent/cert.pem
    private_key_path /etc/td-agent/key.pem
  </transport>
  <parse>
    message_format auto
  </parse>
</source>

<match syslog.**>
  @type copy
  <store>
    @type s3
    s3_bucket ${s3_logs_bucket}
    s3_region ${region}
    path logs/
    <buffer time>
      @type file
      path /opt/td-agent/s3
      timekey 24h # 24 hour partition
      timekey_wait 15m
      timekey_use_utc true # use utc
      chunk_limit_size 1G
    </buffer>
  </store>

  <store>
    @type relabel
    @label @audispd
  </store>

  <store>
    @type splunk_hec # Output to Splunk HTTP event collector
    host ${splunk_http_event_collector_host}
    port ${splunk_http_event_collector_port}
    token ${splunk_http_event_collector_token}
    use_ssl true
    ca_file /etc/td-agent/ca.pem
  </store>

  <store>
    @type cloudwatch_logs
    region ${region}
    log_group_name ${cloudwatch_log_group_name}
    log_stream_name ${cloudwatch_log_stream_name}
    auto_create_stream true
  </store>
</match>

<label @audispd>
  <filter syslog.**>
    @type grep
    <regexp>
      key ident
      pattern /^audispd$/
    </regexp>
  </filter>

  <match syslog.**>
    @type s3
    s3_bucket ${s3_audit_logs_bucket}
    s3_region ${region}
    path ${s3_path}
    <buffer time>
      @type file
      path /opt/td-agent/audispd
      timekey 24h # 24 hour partition
      timekey_wait 15m
      timekey_use_utc true # use utc
      chunk_limit_size 1G
    </buffer>
  </match>
</label>

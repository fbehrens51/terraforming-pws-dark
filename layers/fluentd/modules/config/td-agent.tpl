<label @ERROR>
  <filter>
    @type record_transformer
    <record>
      ident td-agent
      source_address "#{`hostname -I`.strip}"
      host "#{`hostname -s`.strip}"
    </record>
  </filter>
  <match **>
    @type forward
    send_timeout 60s
    recover_wait 10s
    hard_timeout 50s
    <server>
      name localhost
      host 127.0.0.1
    </server>
  </match>
</label>

<label @FLUENT_LOG>
  <filter>
    @type record_transformer
    <record>
      ident td-agent
      source_address "#{`hostname -I`.strip}"
      host "#{`hostname -s`.strip}"
    </record>
  </filter>
  <match fluent.**>
    @type forward
    send_timeout 60s
    recover_wait 10s
    hard_timeout 50s
    <server>
      name localhost
      host 127.0.0.1
    </server>
  </match>
</label>

<label @prometheus>
  <match syslog.**>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
  </metric>
  </match>
</label>

<label @syslog>
<match syslog.**>
  @type copy
  <store>
    @type s3
    s3_bucket ${s3_logs_bucket}
    s3_region ${region}
    path logs/
    <buffer time>
      @type file
      path /data/s3
      timekey 24h # 24 hour partition
      timekey_wait 15m
      timekey_use_utc true # use utc
      chunk_limit_size 1G
    </buffer>
  </store>

  <store>
    @type relabel
      @label @prometheus
    </store>

    <store>
      @type relabel
    @label @audispd
  </store>

  <store>
    @type relabel
    @label @clamav_infections
  </store>

  <store>
    @type cloudwatch_logs
    region ${region}
    log_group_name ${cloudwatch_log_group_name}
    log_stream_name ${cloudwatch_log_stream_name}
    auto_create_stream true
    json_handler yajl
  </store>

  <store>
    @type prometheus
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
    </metric>
  </store>
</match>
</label>

<label @clamav_infections>
  <filter syslog.**>
    @type grep
    <regexp>
      key ident
      pattern /^antivirus$/
    </regexp>
    <regexp>
      key message
      pattern /Infected files: /
    </regexp>
  </filter>

  <filter syslog.**>
    @type parser
    key_name message
    reserve_data true
    <parse>
      @type regexp
      types infections:integer
      expression /Infected files: (?<infections>\d+)/
    </parse>
  </filter>

  <match syslog.**>
    @type prometheus
    <metric>
      name fluentd_clamav_infected_files
      type gauge
      desc The total number of infected files found by clamav
      key infections
      <labels>
        source_address $.source_address
      </labels>
    </metric>
  </match>
</label>

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
      path /data/audispd
      timekey 24h # 24 hour partition
      timekey_wait 15m
      timekey_use_utc true # use utc
      chunk_limit_size 1G
    </buffer>
  </match>
</label>

<source>
  @type prometheus
  port 9200
  metrics_path /metrics
</source>

<source>
  @type prometheus_monitor
</source>

<source>
  @type prometheus_output_monitor
</source>

<source>
  @type forward
  port 24224
  bind 127.0.0.1
  @label @syslog
  add_tag_prefix syslog
</source>

<source>
  @type syslog
  port 8090
  bind 0.0.0.0
  tag syslog
  @label @syslog
  emit_unmatched_lines true
  source_address_key source_address
  <transport tls>
    ca_path /etc/td-agent/ca.pem
    cert_path /etc/td-agent/cert.pem
    private_key_path /etc/td-agent/key.pem
  </transport>
  <parse>
    message_format auto
  </parse>
</source>

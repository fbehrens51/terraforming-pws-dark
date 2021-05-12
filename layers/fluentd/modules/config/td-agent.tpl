# These sources don't actually produce logs, they exist to ensure certain process are spawned by fluentd for self-monitoring
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
  @type http_healthcheck
  port 8888
  bind 0.0.0.0
</source>

# Fluentd's internal error logs
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
    @type copy

    <store>
      @type relabel
      @label @all_logs
    </store>
  </match>
</label>

# Fluentd's internal logs
<label @FLUENT_LOG>
  <filter>
    @type record_transformer
    <record>
      ident td-agent
      source_address "#{`hostname -I`.strip}"
      host "#{`hostname -s`.strip}"
    </record>
  </filter>
  <match **>
    @type copy

    <store>
      @type relabel
      @label @all_logs
    </store>
  </match>
</label>

# This is where all external syslog comes in
<source>
  @type syslog
  port 8090
  bind "#{`hostname -I`.strip}"
  tag syslog
  @label @all_logs
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

# This is where local syslog comes in (to prevent a network roundtrip)
<source>
  @type syslog
  port 8090
  bind 127.0.0.1
  tag syslog
  @label @loopback_logs
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

<label @loopback_logs>
  <filter>
    @type record_transformer
    <record>
      source_address "#{`hostname -I`.strip}"
      host "#{`hostname -s`.strip}"
    </record>
  </filter>
  <match **>
    @type copy

    <store>
      @type relabel
      @label @all_logs
    </store>
  </match>
</label>

# This is where all platform app syslog comes in
<source>
  @type syslog
  port 8091
  bind 0.0.0.0
  tag syslog
  @label @app_logs
  emit_unmatched_lines true
  frame_type octet_count
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

<label @app_logs>
  # Keep system application logs only
  <filter **>
    @type grep
    <regexp>
      key host
      pattern /^system\./
    </regexp>
  </filter>

  <filter **>
    @type parser
    key_name message
    reserve_data true
    hash_value_field event
    <parse>
      @type multi_format
      <pattern>
        format json
      </pattern>
      <pattern>
        format none
      </pattern>
    </parse>
  </filter>

  <match **>
    @type copy

    <store>
      @type relabel
      @label @all_logs
    </store>
  </match>
</label>

<label @all_logs>
  <match **>
    @type copy

    # Write logs to S3 for long-term and Cloudwatch for short-term storage
    <store>
      @type s3
      s3_bucket ${s3_logs_bucket}
      s3_region ${region}
      path "logs/#{ENV['AWSAZ']}/"
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
      @type cloudwatch_logs
      region ${region}
      log_group_name ${cloudwatch_log_group_name}
      log_stream_name ${cloudwatch_log_stream_name}
      auto_create_stream true
      json_handler yajl
    </store>

    # "Fan-out" to various other things
    <store>
      @type relabel
      @label @audispd
    </store>

    <store>
      @type relabel
      @label @clamav_infections
    </store>

    <store>
      @type relabel
      @label @cf_events
    </store>

    <store>
      @type relabel
      @label @prometheus
    </store>
  </match>
</label>

# Send audispd logs to a separate bucket for analysis
<label @audispd>
  <filter **>
    @type grep
    <regexp>
      key ident
      pattern /^audispd$/
    </regexp>
  </filter>

  <match **>
    @type s3
    s3_bucket ${s3_audit_logs_bucket}
    s3_region ${region}
    path "${s3_path}#{ENV['AWSAZ']}/"
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

# Monitor for clamav infections
<label @clamav_infections>
  <filter **>
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

  <filter **>
    @type parser
    key_name message
    reserve_data true
    <parse>
      @type regexp
      types infections:integer
      expression /Infected files: (?<infections>\d+)/
    </parse>
  </filter>

  <match **>
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

<label @cf_events>
  <filter **>
    @type grep
    <regexp>
      key $.event.guid
      pattern /./
    </regexp>
  </filter>

  <match **>
    @type prometheus
    <metric>
      name fluentd_cf_events
      type counter
      desc Cloud Foundry Audit Event Counter
      <labels>
        type $.event.type
      </labels>
    </metric>
  </match>
</label>

# Count input records
<label @prometheus>
  <match **>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records
  </metric>
  </match>
</label>

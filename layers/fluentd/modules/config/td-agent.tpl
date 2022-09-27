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

# s3 access logs
<source>
  @type s3
  @label @s3_logs
  tag s3

  s3_bucket ${s3_access_logs}
  region ${region}
  store_as json

  <sqs>
    queue_name ${s3_logs_queue}
  </sqs>
  <parse>
    @type regexp
    expression /^(?<bucketowner>[^ ]*) (?<bucket>[^ ]*) \[(?<time>.*?)\] (?<remote_ip>[^ ]*) (?<requester>[^ ]*) (?<request_id>[^ ]*) (?<operation>[^ ]*) (?<key>[^ ]*) (?<request_uri>\"[^\"]*\"|-) (?<http_status>-|[0-9]*) (?<error_code>[^ ]*) (?<bytes_sent>[^ ]*) (?<object_size>[^ ]*) (?<total_time>[^ ]*) (?<turn_around_time>[^ ]*) (?<referrer>[^ ]*) (?<user_agent>\"[^\"]*\"|-) (?<version_id>[^ ]*)(?: (?<host_id>[^ ]*) (?<sigv>[^ ]*) (?<cipher_suite>[^ ]*) (?<auth_type>[^ ]*) (?<end_point>[^ ]*) (?<tls_version>[^ ]*))?.*$/
    types bytes_sent:integer,object_size:integer
    time_key time
    time_format %d/%b/%Y:%T %z
    keep_time_key true
  </parse>
</source>

<label @s3_logs>
  <filter>
    @type record_transformer
    <record>
      ident s3_access_logs
      host ${s3_access_logs}
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
    version TLSv1_2
    ciphers "EECDH+AESGCM:EDH+AESGCM"
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
    version TLSv1_2
    ciphers "EECDH+AESGCM:EDH+AESGCM"
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
    version TLSv1_2
    ciphers "EECDH+AESGCM:EDH+AESGCM"
  </transport>
  <parse>
    message_format auto
  </parse>
</source>

<label @app_logs>
  # Keep application logs in these orgs
  <filter **>
    @type grep
    <regexp>
      key host
      pattern /^(system|credhub-service-broker-org)\./
    </regexp>
  </filter>

  <filter **>
    @type record_transformer
    <record>
      ident $${record["host"]}
      host  $${record["ident"]}
    </record>
  </filter>

  <filter **>
    @type parser
    key_name message
    reserve_data true
    reserve_time true
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

  <filter>
    @type record_transformer
    <record>
      fluentd_az "#{ENV['AWSAZ']}"
    </record>
  </filter>

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
      log_rejected_request true
      auto_create_stream true
      json_handler yajl
    </store>

%{if loki_config.enabled ~}
    <store>
      @type loki
      url ${loki_config.loki_url}
      username ${loki_config.loki_username}
      password ${loki_config.loki_password}
      cert /etc/td-agent/loki-client-cert.pem
      key /etc/td-agent/loki-client-key.pem
      <label>
        ident $.ident
        source_address $.source_address
        fluentd_az $.fluentd_az
      </label>
      line_format json
      flush_interval 10s
      flush_at_shutdown true
      buffer_chunk_limit 1m
    </store>
%{~ endif }

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
      @label @credhub_admin
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

# Monitor for credhub admin account access
<label @credhub_admin>
  <filter **>
    @type grep
    <regexp>
      key ident
      pattern /^credhub$/
    </regexp>
    <regexp>
      key message
      pattern /credhub_admin_client/
    </regexp>
  </filter>

  <match **>
    @type prometheus
    <metric>
      name credhub_admin_usage_detected
      type counter
      desc Reports the use of credhub_admin_client
      <labels>
        source_address $.source_address
      </labels>
    </metric>
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

  <filter **>
    @type record_transformer
    renew_record true
    keep_keys event
  </filter>

  <filter **>
    @type record_transformer
    remove_keys $.event.actor_type,$.event.actor_username,$.event.actee_type,$.event.organization_guid,$.event.space_guid,$.event.metadata
  </filter>

  # Send to cloudwatch
  <match **>
    @type copy

    <store>
      @type cloudwatch_logs
      region ${region}
      log_group_name ${cloudwatch_audit_log_group_name}
      log_stream_name ${cloudwatch_log_stream_name}
      log_rejected_request true
      auto_create_stream true
      json_handler yajl
    </store>

    <store>
      @type prometheus
      <metric>
        name fluentd_cf_events
        type counter
        desc Cloud Foundry Audit Event Counter
        <labels>
          type $.event.type
        </labels>
      </metric>
    </store>
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

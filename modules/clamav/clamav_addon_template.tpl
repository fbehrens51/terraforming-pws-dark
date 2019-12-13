product-name: p-antivirus
product-properties:
  .properties.action:
    selected_option: notify
    value: notify
  .properties.daily_db_check_frequency:
    value: 12
  .properties.database_mirrors:
    selected_option: tile_mirror
    value: tile_mirror
  .properties.enforce_cpu_limit:
    selected_option: enabled
    value: enabled
  .properties.enforce_cpu_limit.enabled.cpu_limit:
    value: ${cpu_limit}
  .properties.exclude_paths:
    value: /proc/,/sys/
  .properties.memory_limit:
    value: 1610612736
  .properties.on_access:
    value: ${on_access_scanning}
  .properties.schedule_interval:
    selected_option: daily
    value: daily
  .properties.schedule_interval.daily.first_scheduled_scan_time:
    value: '"00:00"'
  .properties.schedule_interval.daily.last_scheduled_scan_time:
    value: '"23:59"'
  .properties.use_proxy:
    selected_option: disabled
    value: disabled

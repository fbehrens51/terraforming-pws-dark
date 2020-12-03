add_job_to_instance_group:
 instance_group: bosh
 job_name: antivirus
 release_name: antivirus
 release_sha1: ${clamav_release_sha1}
 release_url: ${clamav_release_url}
 job_properties:
  antivirus:
   action: notify
   copy_action_destination: "/var/vcap/data/clamav/found"
   cpu_limit: ${cpu_limit}
   daily_db_check_frequency: 12
   database_mirrors: ${external_mirrors}
   enforce_cpu_limit: enabled
   exclude_paths: [ "/proc/", "/sys/" ]
   first_scheduled_scan_time: "\"00:00\""
   last_scheduled_scan_time: "\"23:59\""
   memory_limit: 1610612736
   move_action_destination: "/var/vcap/data/clamav/found"
   mtls_ca_certificate: ""
   mtls_instance_certificate: ""
   mtls_instance_key: ""
   on_access: ${on_access_scanning}
   proxy_host: null
   proxy_password: null
   proxy_port: null
   proxy_user: null
   schedule_interval: daily
   selected_mirror_type: private_mirror
   whitelist: []

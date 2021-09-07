#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

users:
- name: loki
  system: true
  shell: /sbin/nologin

write_files:
  - content: |
      ${indent(6, loki_configuration)}
    path: /etc/loki/loki.yaml
    permissions: '0644'
    owner: root:root

  - content: |
      [Unit]
      Description=Grafana Loki

      [Service]
      User=loki
      EnvironmentFile=/etc/sysconfig/loki
      ExecStart=/usr/sbin/loki $OPTIONS

      [Install]
      WantedBy=multi-user.target
    path: /usr/lib/systemd/system/loki.service
    permissions: '0644'
    owner: root:root

runcmd:
  - |
    set -ex
    wget --quiet --no-check-certificate -O loki.zip "${loki_location}"
    unzip loki.zip
    mv loki-linux-amd64 loki
    install -o root -g root -m 755 loki /usr/sbin
    rm loki.zip

    if   command -v ec2metadata  > /dev/null; then LOCAL_IP=$(ec2metadata --local-ipv4)
    elif command -v ec2-metadata > /dev/null; then LOCAL_IP=$(ec2-metadata -o | cut -d' ' -f2)
    else false
    fi

    echo "OPTIONS=-config.file=/etc/loki/loki.yaml -server.http-listen-address=$LOCAL_IP -server.grpc-listen-address=$LOCAL_IP" > loki_config
    
    install -m 644 -D loki_config /etc/sysconfig/loki
    rm loki_config

    systemctl daemon-reload
    systemctl start loki
    systemctl enable loki.service

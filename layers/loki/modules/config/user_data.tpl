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

bootcmd:
  - |
    set -ex
    mkdir -p /data
    while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
    if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

mounts:
  - [ "/dev/sdf", "/data", "ext4", "defaults,nofail", "0", "2" ]

write_files:
  - content: |
      ${indent(6, ca_cert)}
    path: /etc/loki/ca.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, server_cert)}
    path: /etc/loki/cert.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, server_key)}
    path: /etc/loki/key.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, client_ca_cert)}
    path: /etc/loki/client-ca.pem
    permissions: '0600'
    owner: root:root

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
      Restart=always

      [Install]
      WantedBy=multi-user.target
    path: /usr/lib/systemd/system/loki.service
    permissions: '0644'
    owner: root:root

  - content: |
      ${indent(6, nginx_http)}
    path: /etc/nginx/conf.d/loki-http.conf
    permissions: '0644'
    owner: root:root

  - content: |
      ${indent(6, nginx_grpc)}
    path: /etc/nginx/conf.d/loki-grpc.conf
    permissions: '0644'
    owner: root:root

  - content: |
      ${indent(6, nginx_gossip)}
    path: /etc/nginx/conf.d/loki-gossip.conf
    permissions: '0644'
    owner: root:root

runcmd:
  - |
    set -exo pipefail

    amazon-linux-extras install -y nginx1
    systemctl enable nginx.service
    systemctl start nginx

    wget --quiet --no-check-certificate -O loki.zip "${loki_location}"
    unzip loki.zip
    mv loki-linux-amd64 loki
    install -o root -g root -m 755 loki /usr/sbin
    rm loki.zip loki
    mkdir -p /var/lib/loki/index /data/wal /data/retention
    chown -R loki:loki /var/lib/loki /data/wal /data/retention

    if   command -v ec2metadata  > /dev/null; then LOCAL_IP=$(ec2metadata --local-ipv4)
    elif command -v ec2-metadata > /dev/null; then LOCAL_IP=$(ec2-metadata -o | cut -d' ' -f2)
    else false
    fi

    echo "OPTIONS=-config.file=/etc/loki/loki.yaml -server.http-listen-address=127.0.0.1 -server.grpc-listen-address=$LOCAL_IP" > loki_config
    
    install -m 644 -D loki_config /etc/sysconfig/loki
    rm loki_config

    systemctl daemon-reload
    systemctl enable loki.service
    systemctl start loki

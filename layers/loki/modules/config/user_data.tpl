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

  - content: |
      # websockets config
      map $http_upgrade $connection_upgrade {
              default upgrade;
              '' close;
          }

      upstream loki {
        server 127.0.0.1:${http_port};
        keepalive 15;
      }

      server {
        # Disable max_body_size since this is the main ingress for log data and is expected to be large
        client_max_body_size 0;

        listen ${local_ip}:${http_port};
        server_name ${server_name};

        # auth_basic "loki auth";
        # auth_basic_user_file /etc/nginx/passwords;

        location / {
          proxy_read_timeout 1800s;
          proxy_connect_timeout 1600s;
          proxy_pass http://loki;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
          proxy_set_header Connection "Keep-Alive";
          proxy_set_header Proxy-Connection "Keep-Alive";
          proxy_redirect off;
        }

        location /ready {
          proxy_pass http://loki;
          proxy_http_version 1.1;
          proxy_set_header Connection "Keep-Alive";
          proxy_set_header Proxy-Connection "Keep-Alive";
          proxy_redirect off;
          auth_basic "off";
        }
      }
    path: /etc/nginx/conf.d/loki-http.conf
    permissions: '0644'
    owner: root:root

  - content: |
      %{ for i, ip in loki_ips ~}
      %{ if ip != local_ip ~}
      upstream loki-${i} {
        server ${ip}:${grpc_port};
        keepalive 15;
      }

      server {
        listen ${local_ip}:${grpc_port} http2;
        server_name loki-${i};

        # auth_basic "loki auth";
        # auth_basic_user_file /etc/nginx/passwords;

        location / {
          grpc_pass grpc://loki-${i}:${grpc_port};
        }
      }
      %{~ endif }
      %{~ endfor }
    path: /etc/nginx/conf.d/loki-grpc.conf
    permissions: '0644'
    owner: root:root

  # - content: |
  #     server {}
  #   path: /etc/nginx/conf.d/gossip.conf
  #   permissions: '0644'
  #   owner: root:root

runcmd:
  - |
    amazon-linux-extras install -y nginx1
    systemctl enable nginx.service
    systemctl start nginx

    set -ex
    wget --quiet --no-check-certificate -O loki.zip "${loki_location}"
    unzip loki.zip
    mv loki-linux-amd64 loki
    install -o root -g root -m 755 loki /usr/sbin
    rm loki.zip loki
    mkdir -p /var/lib/loki/index
    chown -R loki:loki /var/lib/loki

    if   command -v ec2metadata  > /dev/null; then LOCAL_IP=$(ec2metadata --local-ipv4)
    elif command -v ec2-metadata > /dev/null; then LOCAL_IP=$(ec2-metadata -o | cut -d' ' -f2)
    else false
    fi

    echo "OPTIONS=-config.file=/etc/loki/loki.yaml -server.http-listen-address=127.0.0.1 -server.grpc-listen-address=$LOCAL_IP" > loki_config
    
    install -m 644 -D loki_config /etc/sysconfig/loki
    rm loki_config

    systemctl daemon-reload
    systemctl start loki
    systemctl enable loki.service

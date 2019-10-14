# read the cloud-init docs to understand in which "phase" each of the sections (bootcmd vs runcmd) are run.
# example: write_files: occurs before runcmd:

variable "s3_syslog_archive" {}
variable "ca_cert" {}
variable "server_cert" {}
variable "server_key" {}

data "template_file" "user_data" {
  template = <<EOF
bootcmd:
  - mkdir -p /opt/s3_archive
  - while [ ! -e /dev/xvdf ] ; do sleep 1 ; done
  - if [ "$(file -b -s /dev/xvdf)" == "data" ]; then mkfs -t ext4 /dev/xvdf; fi

mounts:
  - [ "/dev/xvdf", "/opt/s3_archive", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -ex
    [ ! -d /opt/s3_archive/bin ] && install -m 700 -d /opt/s3_archive/bin
    [ ! -d /opt/s3_archive/daily_files ] && install -m 700 -d /opt/s3_archive/daily_files
    install -m 750 /run/compress_logs_and_copy_to_s3 /opt/s3_archive/bin/compress_logs_and_copy_to_s3
    #yum install librelp -y

rsyslog:
  configs:
    - filename: 10-cloud-config.conf
      content: |
        # load required modules
        module(load="imtcp" # TCP listener
            StreamDriver.Name="gtls"
            StreamDriver.Mode="1" # run driver in TLS-only mode
            StreamDriver.Authmode="anon"
            )

        # make gtls driver the default and set certificate files
        global(
            DefaultNetstreamDriver="gtls"
            DefaultNetstreamDriverCAFile="/etc/rsyslog.d/ca.pem"
            DefaultNetstreamDriverCertFile="/etc/rsyslog.d/cert.pem"
            DefaultNetstreamDriverKeyFile="/etc/rsyslog.d/key.pem"
            )

        # listeners repeat blocks if more listeners are needed
        # alternatively, use array syntax: port=["514","515",...]

        input(type="imtcp" port="10514" ruleset="writeRemoteData")

        # timereported = time from message
        # timegenerated = time message was received
        $template RemoteStore, "/opt/s3_archive/daily_files/%timegenerated:1:10:date-rfc3339%"

        # now define our ruleset, which also includes threading and queue parameters.

        ruleset(name="writeRemoteData"
            queue.type="fixedArray"
            queue.size="250000"
            queue.dequeueBatchSize="4096"
            queue.workerThreads="4"
            queue.workerThreadMinimumMessages="60000"
           ) {
          action(type="omfile" DynaFile="RemoteStore" ioBufferSize="64k" flushOnTXEnd="off" asyncWriting="on")
        }

  service_reload_command: [systemctl, kill, --kill-who, main, -s, SIGHUP, rsyslog.service]

write_files:
- path: /etc/rsyslog.d/ca.pem
  owner: root:root
  permisions: '0400'
  content: |
    ${indent(4, var.ca_cert)}

- path: /etc/rsyslog.d/cert.pem
  owner: root:root
  permisions: '0400'
  content: |
    ${indent(4, var.server_cert)}

- path: /etc/rsyslog.d/key.pem
  owner: root:root
  permisions: '0400'
  content: |
    ${indent(4, var.server_key)}

- path: /run/compress_logs_and_copy_to_s3
  owner: root:root
  permisions: '0600'
  content: |
    $${script}

- path: /etc/cron.d/compress_logs_and_copy_to_s3
  owner: root:root
  permisions: '0644'
  content: |
    SHELL=/bin/bash
    MAILTO=""
    0 1 * * * root /opt/s3_archive/bin/compress_logs_and_copy_to_s3 $${s3_syslog_archive}

EOF

  vars {
    s3_syslog_archive = "${var.s3_syslog_archive}"
    script            = "${indent(4,file("${path.module}/script.bash"))}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}

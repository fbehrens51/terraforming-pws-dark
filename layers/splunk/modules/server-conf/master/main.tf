variable "indexers_pass4SymmKey" {}
variable "forwarders_pass4SymmKey" {}

data "template_file" "master_server_conf" {
  template = <<EOF
[indexer_discovery]
pass4SymmKey = $${forwarders_pass4SymmKey}
indexerWeightByDiskCapacity = true

[clustering]
mode = master
replication_factor = $${replication_factor}
search_factor = $${search_factor}
pass4SymmKey = $${indexers_pass4SymmKey}
EOF

  vars {
    replication_factor      = "2"
    search_factor           = "2"
    indexers_pass4SymmKey   = "${var.indexers_pass4SymmKey}"
    forwarders_pass4SymmKey = "${var.forwarders_pass4SymmKey}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../user_data.tpl")}"

  vars {
    server_conf_content = "${data.template_file.master_server_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}

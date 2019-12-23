data "template_file" "configure" {
  template = file("${path.module}/configure.sh.tpl")

  vars = {
    domain   = var.root_domain
    basedn   = var.basedn
    admin    = var.admin
    password = var.password
  }
}

data "template_file" "users_schema" {
  template = file("${path.module}/users.ldif.tpl")

  vars = {
    basedn = var.basedn
  }
}

resource "null_resource" "ldap_configuration" {
  triggers = {
    instance_id = var.instance_id
    config      = data.template_file.configure.rendered
    cert        = var.tls_server_cert
    key         = var.tls_server_key
    ca_cert     = var.tls_server_ca_cert
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.ssh_host
    private_key = var.ssh_private_key_pem
  }

  provisioner "file" {
    source      = "${path.module}/conf"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = data.template_file.users_schema.rendered
    destination = "/tmp/conf/users.ldif"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/conf/users",
      "mkdir -p /tmp/conf/certs",
    ]
  }

  provisioner "file" {
    content     = var.tls_server_cert
    destination = "/tmp/conf/certs/ldap_crt.pem"
  }

  provisioner "file" {
    content     = var.tls_server_key
    destination = "/tmp/conf/certs/ldap_key.pem"
  }

  provisioner "file" {
    content     = var.tls_server_ca_cert
    destination = "/tmp/conf/certs/ldap_ca.pem"
  }

  provisioner "file" {
    content     = data.template_file.configure.rendered
    destination = "/tmp/conf/configure.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash -ex /tmp/conf/configure.sh",
    ]
  }
}


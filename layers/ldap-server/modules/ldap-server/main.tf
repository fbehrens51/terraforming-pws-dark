data "template_file" "configure" {
  template = file("${path.module}/configure.sh.tpl")

  vars = {
    domain   = var.root_domain
    basedn   = var.basedn
    admin    = var.admin
    password = var.password
  }
}

data "template_file" "people_schema" {
  template = file("${path.module}/users.ldif.tpl")

  vars = {
    basedn = var.basedn
    ou     = "People"
  }
}

data "template_file" "applications_schema" {
  template = file("${path.module}/users.ldif.tpl")

  vars = {
    basedn = var.basedn
    ou     = "Applications"
  }
}


data "template_file" "servers_schema" {
  template = file("${path.module}/users.ldif.tpl")

  vars = {
    basedn = var.basedn
    ou     = "Servers"
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
    type         = "ssh"
    user         = var.bot_user
    host         = var.private_ip
    private_key  = var.bot_key_pem
    bastion_host = var.bastion_host
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"Running cloud-init status --wait > /dev/null\"",
      "sudo cloud-init status --wait > /dev/null",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/conf"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = data.template_file.people_schema.rendered
    destination = "/tmp/conf/people.ldif"
  }

  provisioner "file" {
    content     = data.template_file.applications_schema.rendered
    destination = "/tmp/conf/applications.ldif"
  }

  provisioner "file" {
    content     = data.template_file.servers_schema.rendered
    destination = "/tmp/conf/servers.ldif"
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


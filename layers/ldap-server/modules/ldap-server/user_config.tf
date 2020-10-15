data "template_file" "ldif_roles" {
  count = length(var.users)

  template = <<EOT
role: ${join("\nrole: ", split(",", var.users[count.index]["roles"]))}
EOT

}

data "template_file" "ldif_file" {
  count    = length(var.users)
  template = file("${path.module}/user.ldif.tpl")

  vars = {
    basedn   = var.basedn
    username = var.users[count.index]["username"]
    name     = var.users[count.index]["name"]
    ou       = var.users[count.index]["ou"]
    roles    = data.template_file.ldif_roles[count.index].rendered
  }
}

data "template_file" "ldapadd" {
  count = length(var.users)

  # when = destroy is buggy and doesn't really work. (https://github.com/hashicorp/terraform/issues/13549)
  # instead, always delete / re-add the user when the config changes
  template = <<EOT
    ldapdelete -D '${var.admin}' -w '${var.password}' -H ldap:// 'uid=${var.users[count.index]["username"]},ou=${var.users[count.index]["ou"]},${var.basedn}' || true
    ldapadd -x -D "${var.admin}" -w '${var.password}' -H ldap:// -f /tmp/conf/users/${var.users[count.index]["username"]}.ldif
EOT

}

resource "null_resource" "user_configuration" {
  count = length(var.users)

  triggers = {
    instance_id   = var.instance_id
    server_config = data.template_file.configure.rendered
    ldif          = data.template_file.ldif_file[count.index].rendered
    cert          = var.user_certs[var.users[count.index]["username"]]
  }

  connection {
    type         = "ssh"
    user         = var.bot_user
    host         = var.private_ip
    private_key  = var.bot_key_pem
    bastion_host = var.bastion_host
  }

  depends_on = [null_resource.ldap_configuration]

  provisioner "file" {
    content     = data.template_file.ldif_file[count.index].rendered
    destination = "/tmp/conf/users/${var.users[count.index]["username"]}.ldif"
  }

  provisioner "file" {
    content     = "${var.user_certs[var.users[count.index]["username"]]}}"
    destination = "/tmp/conf/users/${var.users[count.index]["username"]}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "openssl x509 -in /tmp/conf/users/${var.users[count.index]["username"]}.pem -inform pem -outform der -out /tmp/conf/users/${var.users[count.index]["username"]}.der",
    ]
  }

  provisioner "file" {
    content     = data.template_file.ldapadd[count.index].rendered
    destination = "/tmp/conf/users/add-${var.users[count.index]["username"]}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash -ex /tmp/conf/users/add-${var.users[count.index]["username"]}.sh",
    ]
  }
}


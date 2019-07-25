data "template_file" "ldif_roles" {
  count = "${length(var.users)}"

  template = <<EOT
role: ${join("\nrole: ", split(",", lookup(var.users[count.index], "roles")))}
EOT
}

data "template_file" "ldif_file" {
  count    = "${length(var.users)}"
  template = "${file("${path.module}/user.ldif.tpl")}"

  vars = {
    basedn   = "${var.basedn}"
    username = "${lookup(var.users[count.index], "username")}"
    name     = "${lookup(var.users[count.index], "name")}"
    email    = "${lookup(var.users[count.index], "email")}"
    roles    = "${data.template_file.ldif_roles.*.rendered[ count.index ]}"
  }
}

data "template_file" "ldapadd" {
  count = "${length(var.users)}"

  # when = destroy is buggy and doesn't really work. (https://github.com/hashicorp/terraform/issues/13549)
  # instead, always delete / re-add the user when the config changes
  template = <<EOT
    ldapdelete -D '${var.admin}' -w '${var.password}' -H ldap:// 'uid=${lookup(var.users[count.index], "username")},${var.basedn}' || true
    ldapadd -x -D "${var.admin}" -w '${var.password}' -H ldap:// -f /tmp/conf/users/${lookup(var.users[count.index], "username")}.ldif
EOT
}

resource "null_resource" "user_configuration" {
  count = "${length(var.users)}"

  triggers = {
    instance_id   = "${var.instance_id}"
    server_config = "${data.template_file.configure.rendered}"
    ldif          = "${data.template_file.ldif_file.*.rendered[ count.index ]}"
    cert          = "${lookup(var.user_certs, lookup(var.users[count.index], "username"))}"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = "${var.ssh_host}"
    private_key = "${var.ssh_private_key_pem}"
  }

  depends_on = ["null_resource.ldap_configuration"]

  provisioner "file" {
    content     = "${data.template_file.ldif_file.*.rendered[ count.index ]}"
    destination = "/tmp/conf/users/${lookup(var.users[count.index], "username")}.ldif"
  }

  provisioner "file" {
    content     = "${lookup(var.user_certs, lookup(var.users[count.index], "username"))}}"
    destination = "/tmp/conf/users/${lookup(var.users[count.index], "username")}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "openssl x509 -in /tmp/conf/users/${lookup(var.users[count.index], "username")}.pem -inform pem -outform der -out /tmp/conf/users/${lookup(var.users[count.index], "username")}.der",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.ldapadd.*.rendered[ count.index ]}"
    destination = "/tmp/conf/users/add-${lookup(var.users[count.index], "username")}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash -ex /tmp/conf/users/add-${lookup(var.users[count.index], "username")}.sh",
    ]
  }
}

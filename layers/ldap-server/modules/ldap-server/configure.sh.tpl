#!/usr/bin/env bash

while [ ! -f /var/lib/cloud/instance/boot-finished ] ; do sleep 1; done

cd $(dirname $0)

sudo apt-get update

sudo apt-get install -y nginx

sudo cp certs/ldap_crt.pem /etc/ssl/certs/ldap.crt
sudo cp certs/ldap_key.pem /etc/ssl/certs/ldap.key
sudo cp certs/ldap_ca.pem /etc/ssl/certs/ldap-ca.crt
sudo cp ldap.nginx.conf /etc/nginx/nginx.conf
sudo systemctl restart nginx.service

export DEBIAN_FRONTEND='non-interactive'

# install ldap and set the domain to ${domain} and admin password to ${password}
cat <<HERE | sudo debconf-set-selections
slapd slapd/password1 password ${password}
slapd slapd/internal/adminpw password ${password}
slapd slapd/internal/generated_adminpw password ${password}
slapd slapd/password2 password ${password}

slapd slapd/unsafe_selfwrite_acl note
slapd slapd/purge_database boolean true
slapd slapd/domain string ${domain}
slapd slapd/ppolicy_schema_needs_update select abort installation
slapd slapd/invalid_config boolean true
slapd slapd/move_old_database boolean true
slapd slapd/backend select MDB
slapd shared/organization string pcfeagle
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
slapd slapd/password_mismatch note
HERE

sudo apt-get install -y slapd ldap-utils

sudo -u openldap slapadd -b cn=config -F /etc/ldap/slapd.d -l extendedperson.ldif
sudo systemctl restart slapd.service
sleep 5
ldapadd -x -D "${admin}" -w ${password} -H ldap:// -f people.ldif
ldapadd -x -D "${admin}" -w ${password} -H ldap:// -f applications.ldif
ldapadd -x -D "${admin}" -w ${password} -H ldap:// -f servers.ldif


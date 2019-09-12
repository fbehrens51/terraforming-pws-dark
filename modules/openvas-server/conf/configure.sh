#!/usr/bin/env bash

set -ex

while [ ! -f /var/lib/cloud/instance/boot-finished ] ; do sleep 1; done

# Resources:
# https://docs.greenbone.net/GSM-Manual/gos-3.1/en/omp.html
# http://www.openvas.org/omp-2-0.html

cat <<HERE | sudo debconf-set-selections
openvas9-scanner        openvas-scanner/enable_redis    boolean true
HERE

sudo apt install -y software-properties-common
sudo add-apt-repository -u -y ppa:mrazavi/openvas
# texlive-latex-extra is needed for pdf reports
sudo apt-get install -y openvas9 sqlite3 texlive-latex-extra

# XML tools, e.g. xml_pp
sudo apt install xml-twig-tools

sudo greenbone-nvt-sync
sudo greenbone-scapdata-sync
sudo greenbone-certdata-sync

# TODOs:
# 1. the cidr block need to be dynamic
# 2. the host need to be configurable

sudo sed -i 's/#ALLOW_HEADER_HOST=/ALLOW_HEADER_HOST=openvas.pcfeagle.cf-app.com/' /etc/default/openvas-gsa
sudo sed -i 's/#MANAGER_ADDRESS=/MANAGER_ADDRESS=/' /etc/default/openvas-gsa
sudo sed -i 's/#MANAGER_PORT_NUMBER=/MANAGER_PORT_NUMBER=/' /etc/default/openvas-gsa

sudo sed -i 's/# LISTEN_ADDRESS.*/LISTEN_ADDRESS="127.0.0.1"/' /etc/default/openvas-manager
sudo sed -i 's/# PORT_NUMBER=9390/PORT_NUMBER=9390/' /etc/default/openvas-manager

# restart to load the latest vulnerability plugins
sudo service openvas-gsa restart
sudo service openvas-manager restart
sudo service openvas-scanner restart
sudo openvasmd --rebuild --progress

# enable the services
sudo systemctl enable openvas-scanner
sudo systemctl enable openvas-manager
sudo systemctl enable openvas-gsa

# change the password of the openvas server
admin_password="pizza12!"
sudo openvasmd --user=admin --new-password="$admin_password"

omp="omp -u admin -w $admin_password"

schedule_id=$($omp --xml=- <<EOF | sed 's/.*id="\([^"]*\)".*/\1/'
<create_schedule>
  <name>Every night</name>
  <period>
    1
    <unit>day</unit>
  </period>
  <first_time>
    <minute>0</minute>
    <hour>21</hour>
  </first_time>
  <timezone>America/New_York</timezone>
</create_schedule>
EOF
)

$omp --xml=- <<EOF
<create_target>
  <name>Combine-1 VPC</name>
  <hosts>10.0.4.0/24</hosts>
</create_target>
EOF

target_id=$($omp --get-targets | grep 'Combine-1 VPC' | awk '{print $1}')
config_id=$($omp -g | egrep 'Full and fast$' | awk '{print $1}')

# Change the task to use the daily schedule
# $omp --create-task --name='Full scan' --target=$target_id --config=$config_id
$omp --xml=- <<EOF
<create_task>
  <name>Full scan</name>
  <target id="$target_id"/>
  <schedule id="$schedule_id"/>
  <config id="$config_id"/>
</create_task>
EOF

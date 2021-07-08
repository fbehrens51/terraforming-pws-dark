- Pause the pipeline
- create the appropriate folder in the env (do not committ) and run this layer to create the new parameter group (potentially could still exist from PAS DB migration from a while back) and new DB
  ```hcl
  include {
    path = "${find_in_parent_folders()}"
  }
  
  dependencies {
  paths = ["../bootstrap_control_plane_foundation"]
  }
  
  inputs = {
  }
  ```
- log on to the cp bosh director
```bash
sudo -i
shutdown -h now
```

- log on to the cp om instance
  create, update variables, and run the following script
```bash
#!/usr/bin/env bash

MARIADB_HOSTNAME=''
MYSQL_HOSTNAME=''
PASSWORD=''

set -xe

#run on OM
mysqldump \
--single-transaction \
--host=${MARIADB_HOSTNAME} \
--user=concourse \
--password=${PASSWORD} \
--databases director \
> /tmp/MariaDB_dump.sql

echo "create database director;" > /tmp/createDB.sql

mysql \
--host=${MYSQL_HOSTNAME} \
--user=concourse \
--password=${PASSWORD} \
< /tmp/createDB.sql

mysql \
--host=${MYSQL_HOSTNAME} \
--user=concourse \
--password=${PASSWORD} \
director \
 < /tmp/MariaDB_dump.sql

rm /tmp/MariaDB_dump.sql

```

- from SJB or bootstrap run the following to rename the existing DB and apply the parameter group
```bash
#!/usr/bin/env bash

set -x

db_identifier="<existing db Identifier here... e.g. pws-dark-ci-control-plane-mysql>"
aws rds modify-db-instance --db-instance-identifier $db_identifier --db-parameter-group-name mariadb-read-only --apply-immediately

status="unkown"

until [ $status == "available" ]
do
	status=$(aws rds describe-db-instances --db-instance-identifier $db_identifier |jq -r .DBInstances[].DBInstanceStatus)
	if [ $status == "pending-reboot" ]; then
	  echo "reboot the instance"
	  break
	fi
	echo $status
	sleep 15
done

echo "db $db_identifier $status"
sleep 60

if [ $status == "available" ]; then
	aws rds modify-db-parameter-group --db-parameter-group-name mariadb-read-only --parameters "ParameterName='read_only',ParameterValue=1,ApplyMethod=immediate"
fi

echo "db $db_identifier $status"

```

- from SJB or bootsrap run the following:
  ```bash
  export db_identifier="<e.g. pws-dark-ci-control-plane-mysql>"
  aws rds modify-db-instance --db-instance-identifier $db_identifier --new-db-instance-identifier "${db_identifier}-mariadb" --apply-immediately
  ```
    - can check on status via (will get an error until rename occurs:
  ```bash
  aws rds describe-db-instances --db-instance-identifier "${db_identifier}-mariadb" |jq -r .DBInstances[].DBInstanceStatus
  ```
    - once available rename new DB to expected name in TF
  ```bash
  aws rds modify-db-instance --db-instance-identifier "${db_identifier}-mysql" --new-db-instance-identifier "${db_identifier}" --apply-immediately  
  ```
    - can check on status via (will get an error until rename occurs:
  ```bash
  aws rds describe-db-instances --db-instance-identifier "${db_identifier}" |jq -r .DBInstances[].DBInstanceStatus
  ```

    - CD
  ```bash
  cd ~/workspace/<env_project>/live/<env>/bootstrap_control_plane_foundation
  ```

    - edit terragrunt.hcl to add the following:
  ```hcl
    control_plane_db_engine = "mysql"
    control_plane_db_engine_version = "5.7"
  ```
    - run TF (apply should say it's updating the password but nothing else, and FYI it's updating the password with the same password)
  ```bash
  terragrunt init
  terragrunt state rm module.mysql.aws_db_instance.rds
  terragrunt import module.mysql.aws_db_instance.rds "${db_identifier}"
  terragrunt apply  
  ```

    - Restart bosh/0
    - once available, log into om ui and apply changes to Director only
    - you should now be able to unpause everything (ensure you committed the terragrunt.hcl changes for bootstrap_control_plane_foundation, but not this layer's env directory)

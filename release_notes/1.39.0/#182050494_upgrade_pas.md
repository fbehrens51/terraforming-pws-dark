This is a manual operation:
1. Pause all pipelines
1. VERIFY EXISTING DATABASE DOESN'T HAVE PENDING MAINTENANCE IN AWS CONSOLE
```bash
cd ~/workspace/pws-dark-environments/live/<ENV>-foundation/pas
export rds_address=$(  terragrunt output -json rds_address  | gojq -re . )
export rds_username=$( terragrunt output -json rds_username | gojq -re . )
export rds_password=$( terragrunt output -json rds_password | gojq -re . )
export instance_name=${rds_address%%.*}  # pws-dark-blue in this example
export rds_arn=$(aws rds describe-db-instances --db-instance-identifier ${instance_name} | gojq -re '.DBInstances[].DBInstanceArn')
aws rds describe-pending-maintenance-actions --resource-identifier ${rds_arn}
```
Should return
```json
{
    "PendingMaintenanceActions": []
}
```
and NOT
```json
{
    "PendingMaintenanceActions": [
        {
            "ResourceIdentifier": "arn:aws:rds:us-east-2:623687983927:db:pws-dark-blue",
            "PendingMaintenanceActionDetails": [
                {
                    "Action": "system-update",
                    "Description": "New Operating System update is available"
                }
            ]
        }
    ]
}
```
The maintenance should be resolved PRIOR to starting the upgrade process. (or it will happen during the `modify-db-instance` operations)
1. Perform maintenance (matches this example)
```bash
#show DB connections if interested
ssh <ENV>_om "mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<< 'select id, user, host, db, command, time, state, info from information_schema.processlist order by db;'" | column -t
aws rds apply-pending-maintenance-action --opt-in-type immediate --resource-identifier "${rds_arn}" --apply-action system-update
```
1. Create read replica of pas mysql db
```bash
aws rds create-db-instance-read-replica --db-instance-identifier "${instance_name}-replica" --source-db-instance-identifier ${instance_name}
aws rds wait db-instance-available --db-instance-identifier "${instance_name}-replica"
# elapsed time ~ 8 minutes
```
1. Upgrade v5.7 read-replica to v8
```bash
# make sure the new replica has "sync'd up -  the "show" command is different for 5.7 vs 8
ssh <ENV>_om "mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<< 'show slave status\G'"
# find the latest version of mysql v8 - minor versions upgrades will happend during maintenance windows ... so just pick up the latest now
#target_version=$(aws rds describe-db-engine-versions | gojq -re '[.DBEngineVersions[]| select((.Engine=="mysql") and (.EngineVersion | match("^8\\.\\d+\\.\\d+"))) ] | sort_by(.EngineVersion)[-1].EngineVersion')
date
aws rds modify-db-instance --db-instance-identifier "${instance_name}-replica" --engine-version 8.0 --allow-major-version-upgrade --apply-immediately
date
sleep 30 # Give the "modify command a chance to start so the wait doesn't exit fast because no modification was found
aws rds wait db-instance-available --db-instance-identifier "${instance_name}-replica"
date
# elapsed time ~ 25 minutes
```
1. Run commands to verify replication status
```bash
ssh <ENV>_om "mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<< 'show replica status\G'"
```
1. Shutdown BOSH
```bash
# This could cause a Healthwatch alert
bosh tasks       # Check for no active deploys: wait if necessary
ssh <ENV>_bosh   # SSH into the BOSH Director.
sudo monit stop all # shutdown bosh
```
1. Modify current DB parameter group for read-only.
```bash
aws rds create-db-parameter-group --db-parameter-group-name "${instance_name}-read-only" --db-parameter-group-family mysql5.7 --description "param group used to make legacy 5.7 db read-only"
aws rds modify-db-parameter-group --db-parameter-group-name "${instance_name}-read-only" --parameters ParameterName=read_only,ParameterValue=1,ApplyMethod=immediate
aws rds modify-db-instance --db-instance-identifier "${instance_name}" --db-parameter-group-name "${instance_name}-read-only" --apply-immediately
sleep 30
aws rds wait db-instance-available --db-instance-identifier ${instance_name}
# elapsed time ~ 3 minutes
```
1. Promote v8 replica to standalone
```bash
# Verify replication status is current
ssh blue_om "mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<< 'show replica status\G'"
aws rds promote-read-replica --db-instance-identifier "${instance_name}-replica" --backup-retention-period 7 --deletion-protection --multi-az
aws rds wait db-instance-available --db-instance-identifier "${instance_name}-replica"
# elapsed time ~ 2 minutes
```
1. Rename DB to DB-old
```bash
# Rename to free up the name
# renaming causes a reboot of instance
# DNS can take upto 10 minutes to update.
old_ip="$(dig +short ${instance_name})"
aws rds modify-db-instance --db-instance-identifier "${instance_name}" --new-db-instance-identifier "${instance_name}-old" --apply-immediately
# let the operation start before we wait
sleep 15
# wait for the old to disappear
aws rds wait db-instance-available --db-instance-identifier ${instance_name}
# wait for the new name "-old" to appear to know the rename has completed (AWS weirdness)
aws rds wait db-instance-available --db-instance-identifier "${instance_name}-old"
```
1. Rename DB-new to DB (this DB is LIVE)
```bash
aws rds modify-db-instance --db-instance-identifier "${instance_name}-replica" --new-db-instance-identifier "${instance_name}" --apply-immediately
# let the operation start before we wait
sleep 15
# wait for "-replica" to disappear - results in an error
aws rds wait db-instance-available --db-instance-identifier "${instance_name}-replica"
# wait for the new name "${instance_name}" to appear to know the rename has completed (AWS weirdness)
aws rds wait db-instance-available --db-instance-identifier ${instance_name}
```
1. Restart BOSH
```bash
sudo monit start all # restart bosh
sleep 30
sudo monit restart uaa # restart uaa - needed for a depenedency
```
1. Apply changes to delete the parameter group
1. Manually delete the old database


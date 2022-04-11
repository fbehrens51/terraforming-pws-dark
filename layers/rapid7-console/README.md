# Rapid7 Security Console


## SC CloudFormation Template

* Pulled down from url provided in AWS Marketplace:
  * AWS Marketplace: https://aws.amazon.com/marketplace/pp/prodview-ehx4plo4j3nom?ref=cns_srchrow
  * currently: https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/9077b9ec-84f0-40c1-a301-d930d84fdd61.c035342a-4c62-4dda-95c3-cdd229247616.template
* Updated Template to:
  * output InstanceID (for use in target group attachment)
  * add Name tag (currently hard coded to r7-console)
  * rename inline policy to have R7 prefix (easier to identify this way and since we had to add another below as well)
  * add inline policy to give access to S3 (to make it easer to copy backups, etc. to S3)
* OS username is `nexpose` and is using the env bot key

## Replacing the Console currently requires manual staps:
1. Run a backup & copy out to S3
   * On existing/old instance:
     * Run Platform independent DB backup (via admin page)
     * Copy backup out to S3 bucket (pws-dark-ci-rapid7)
       * `aws s3 cp /opt/rapid7/nexpose/nsc/backups/nxbackup_<2022_04_11>.zip s3://pws-dark-ci-rapid7/backups/`
2. Copy of pk creds from /opt/rapid7/nexpose/shared/conf/creds.kspw
  * `aws s3 cp /opt/rapid7/nexpose/shared/conf/creds.kspw s3://pws-dark-ci-rapid7/conf/` 
3. Run TF and wait for it to complete
4. Log on to host (nexpose user/bot key) & `sudo -i`
5. Create backups directory:
  * `mkdir /opt/rapid7/nexpose/nsc/backups/`
6. Pull backup down into the backups directory:
   * `wget https://pws-dark-ci-r7.s3.us-west-2.amazonaws.com/backups/nxbackup_2022_04_11.zip`
7. Wait for instance to finish updating (currently ~1 hour, but this will vary as we update the CF template and they release new AMIs)
   1. `tail -f /opt/rapid7/nexpose/nsc/logs/update.log`
8. log into console ui and restore backup via admin page
   1. nxadmin/<instance-id>
   2. It will immediately prompt you to update the password, ensure you save it
9. Click on Admin and Manage link
   1. close out any prompts for license key as it will be restored from the backup
10. The backup file that you copied to the backups directory should be listed under the restore local backups section
    1. Click restore and wait (~1hr)



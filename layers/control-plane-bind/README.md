**Deployment Notes:**
- add the following to terraform.tfvars in the root of your live/<env> with the appropriate domain for the environment
```bash
endpoint_domain = "amazonaws.com"
```
- pause all tf jobs in concourse
- create new layers w/terragrunt.hcl for each
- comment out new output (if already pointing to updated tf code, otherwise you can grab the output before pointing to the new code

```bash
  //output "control_plane_rds_cidr_block" {
  //  value = local.rds_cidr_block
  //}
```
- run migration of state:

```bash
cd <env>/bootstrap_control_plane
terragrunt state pull > /tmp/original_state.json
terragrunt state list|grep 'module.nat'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.uaa_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_bootstrap'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.credhub_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_subnet'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.rds_subnet_group'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.postgres'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.ops_manager'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.om_key_pair'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.mysql'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.concourse_nlb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_s3_bucket'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_route_table_association.sjb_route_table_assoc
terragrunt state rm random_integer.bucket random_string.credhub_client_secret

cd <env>/control-plane-nats
terragrunt init
terragrunt state push /tmp/original_state.json
terragrunt state list|grep 'module.public_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.private_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_vpc_endpoint.cp_ec2
terragrunt state rm aws_security_group.vms_security_group
terragrunt state list|grep 'aws_route_table_association.private_route_table_assoc'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_route_table_association.public_route_table_assoc'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.uaa_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_bootstrap'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.credhub_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_subnet'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.rds_subnet_group'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.postgres'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.ops_manager'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.om_key_pair'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.mysql'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.concourse_nlb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_s3_bucket'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_route_table_association.sjb_route_table_assoc
terragrunt state rm random_integer.bucket random_string.credhub_client_secret

cd <env>/boostrap_sjb
terragrunt init
terragrunt state push /tmp/original_state.json
terragrunt state list|grep 'module.nat'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.public_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.private_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_vpc_endpoint.cp_ec2
terragrunt state rm aws_security_group.vms_security_group
terragrunt state list|grep 'module.uaa_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.credhub_elb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.rds_subnet_group'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.postgres'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.ops_manager'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.om_key_pair'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.mysql'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.concourse_nlb'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_s3_bucket'|xargs -I{} terragrunt state rm {}
terragrunt state rm random_integer.bucket random_string.credhub_client_secret
terragrunt state list|grep 'aws_route_table_association.private_route_table_assoc'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_route_table_association.public_route_table_assoc'|xargs -I{} terragrunt state rm {}

cd <env>/bootstrap_control_plane_foundation
terragrunt init
terragrunt state push /tmp/original_state.json
terragrunt state list|grep 'module.nat'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.public_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.private_subnets'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_vpc_endpoint.cp_ec2
terragrunt state rm aws_security_group.vms_security_group
terragrunt state rm random_integer.bucket random_string.credhub_client_secret
terragrunt state list|grep 'aws_route_table_association.private_route_table_assoc'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'aws_route_table_association.public_route_table_assoc'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_bootstrap'|xargs -I{} terragrunt state rm {}
terragrunt state list|grep 'module.sjb_subnet'|xargs -I{} terragrunt state rm {}
terragrunt state rm aws_route_table_association.sjb_route_table_assoc
```

...

- uncomment `control_plane_rds_cidr_block`
- remove `control_plane_vpc_dns` from paperwork/prereqs.tfvars and add the following to the paperwork/terragrunt.hcl (replacing with enterprise dns servers on location) `control_plane_vpc_dns = ["8.8.8.8","8.8.4.4"]`
- tf apply via cmd line
    - scaling-params (add output for bind in cp)
    - paperwork (adds new control_plane_vpc_dns output)
    - boostrap_control_plane (adds control_plane_rds_cidr_block output and cleans up old output)
    - control-plane-bind (creates new servers and corresponding SGs, etc)
    - control-plane-nats (cleans up old output)
    - bootstrap_sjb (cleans up old output)
    - boostrap_control_plane_foundation (cleans up old output)
    - sjb (replaces SJB instances due to new user data for dnsmasq and cleans up old output)
    - bind (no changes, just pulling remote state from new layer)
    - bootstrap_isolation_segment_vpc (no changes, just pulling remote state from new layer)
    - control-plane-om-config (updates DNS settings for control plane network config)
- let configure-concourse-bosh-director run (should be triggered by new director config created by control-plane-om-config layer)
- let deploy-concourse-bosh-director complete.
- ensure latest TF has been verified and env project changes committed, then unpause pipeline jobs
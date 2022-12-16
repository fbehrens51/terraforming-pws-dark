As part of #182884393
* create a VPC, record ID and region
* create the env structure:

```bash
export env=${TF_ENV:='ENV1'}
export environment-repo=${TF_ENVIRONMENT_REPO:='/home/ec2-user/workpace/pws-dark-environments'}
mkdir -p ${environment}/test-suite
mkdir -p ${environment}/test-suite/${env}
cd ${environment}/test-suite/${env}
touch pipeline-vars.yml
mkdir lb-suite
mkidr lb-suite/tests
mkdir lb-suite/bootstrap
mkdir ec2-suite
mkdir ec2-suite/tests
mkdir ec2-suite/bootstrap
```

vi <base env dir>/pipeline-vars.yml
```yml
$ cat pipeline-vars.yml 
#@data/values
---

region: <<region>>
s3_endpoint: https://s3.<<...>>
env_path: test-suite/<<env>>

#git repos
environment_repo_url: <<env project git remote>>
environment_repo_branch: <<branch>>

terraforming_pws_dark_repo_url: <<tf-pws-dark project git remote>>
terraforming_pws_dark_repo_branch: <<branch>>

pcf_eagle_automation_repo_url: <<pcf-eagle-automation project git remote>>
pcf_eagle_automation_repo_branch: <<branch>>

#borrowing from live envc for now, should we set up separate buckets for the test-suites?
mirror_bucket: <<mirror bucket for underlying concourse env>>
public_bucket: <<public bucket for underlying concourse env>>

#pwsd settings
release_channel: <<on location stable>>
artifact_repo_bucket: <<artifact repo bucket>>
artifact_repo_bucket_region: <<artifact repo region>>
artifact_repo_bucket_endpoint: <<artifact repo endpoint.... https://S3......>>
```


**ec2-suite set up:**
```bash
cd ec2-suite
vi terragrunt.hcl
```

terragrunt.hcl
```hcl
remote_state {
  backend = "s3"

  config = {
    bucket         = "<<state bucket>>"
    key            = "ec2-suite/${path_relative_to_include()}"
    region         = "<<region>>"
    encrypt        = true
    dynamodb_table = "<<dynamo state lock table>>"
    disable_bucket_update = true
  }
}

terraform {
  source = "${run_cmd("--terragrunt-quiet", "../get_layer_name.sh")}"

  extra_arguments "shared_variables" {
    env_vars = {
      AWS_DEFAULT_REGION = "<<region>>"
    }

    commands = "${get_terraform_commands_that_need_vars()}"

    required_var_files = [
      "${get_parent_terragrunt_dir()}/terraform.tfvars",
    ]
  }
}


skip = true

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF

terraform {
  backend "s3" {
  }
}
EOF
}

```

`vi get_layer_name.sh`

```bash
#!/usr/bin/env bash

TF_PWS_DARK_REPO=${TF_PWS_DARK_REPO:-"<<terraforming-pws-dark remote>>"}

layer_name=$(basename $PWD)

echo -n "$TF_PWS_DARK_REPO//test/ec2-suite/$layer_name"
```

`vi terraform.tfvars`
```hcl
availability_zones = [
"<<AZ A>>",
"<<AZ B>>",
"<<AZ C>>",
]

global_vars = {
name_prefix = "<<name, e.g. test1>>"
env_name    = "<<name, e.g. test1>>"
instance_tags = {
operating-system = "test-os"
}
global_tags = {
env             = "<<name, e.g. test1>>"
foundation_name = "<<name, e.g. test1>>"
}
}

internetless = true

region = "<<region>>"
vpc_id = "<<id of the vpc created>>"
```

**ec2-suite/bootstrap**

`vi terragrunt.hcl`
```hcl
include {
  path = find_in_parent_folders()
}

inputs = {
}
```

**ec2-suite/tests**

`vi terragrunt.hcl`
```hcl
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../bootstrap"]
}

inputs = {
}
```


**lb-suite set up:**
```bash
cd lb-suite
vi terragrunt.hcl
```

terragrunt.hcl
```hcl
remote_state {
  backend = "s3"

  config = {
    bucket         = "<<state bucket>>"
    key            = "lb-suite/${path_relative_to_include()}"
    region         = "<<region>>"
    encrypt        = true
    dynamodb_table = "<<dynamo state lock table>>"
    disable_bucket_update = true
  }
}

terraform {
  source = "${run_cmd("--terragrunt-quiet", "../get_layer_name.sh")}"

  extra_arguments "shared_variables" {
    env_vars = {
      AWS_DEFAULT_REGION = "<<region>>"
    }

    commands = "${get_terraform_commands_that_need_vars()}"

    required_var_files = [
      "${get_parent_terragrunt_dir()}/terraform.tfvars",
    ]
  }
}


skip = true

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF

terraform {
  backend "s3" {
  }
}
EOF
}

```

`vi get_layer_name.sh`

```bash
#!/usr/bin/env bash

TF_PWS_DARK_REPO=${TF_PWS_DARK_REPO:-"<<terraforming-pws-dark remote>>"}

layer_name=$(basename $PWD)

echo -n "$TF_PWS_DARK_REPO//test/lb-suite/$layer_name"
```

`vi terraform.tfvars`
```hcl
availability_zones = [
"<<AZ A>>",
"<<AZ B>>",
"<<AZ C>>",
]

global_vars = {
name_prefix = "<<name, e.g. test1>>"
env_name    = "<<name, e.g. test1>>"
instance_tags = {
operating-system = "test-os"
}
global_tags = {
env             = "<<name, e.g. test1>>"
foundation_name = "<<name, e.g. test1>>"
}
}

internetless = true

region = "<<region>>"
vpc_id = "<<id of the vpc created>>"
```

**lb-suite/bootstrap**

`vi terragrunt.hcl`
```hcl
include {
  path = find_in_parent_folders()
}

inputs = {
}
```

**lb-suite/tests**

`vi terragrunt.hcl`
```hcl
include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../bootstrap"]
}

inputs = {
}
```

* terragrunt init --upgrade (within 1 of the layers of each suite e.g. ec2-suite/bootstrap & lb-suite/bootstrap, this will create the s3 and dynamo table is they don't already exist)
* update-test-pipeline.sh (pcf-eagle-automation)
     ```bash
    ./update-test-pipeline.sh <<target>> <<environment-repo>>/test-suite/<<test env>>/pipeline-vars.yml
    ```
# terraforming-aws example

This is an example template that can be used to manage an environment (in this case, a dev environment that we've named "ssh".)

The intention is to allow users to check the "main.tf" file into source control. The template includes information on where to store the state remotely, and replaces the terraform.tfvars file.

Because the configuration is contained withing the example "main.tf" file it is possible to manage existing infra on day 2 without needing to re-establish a potentially unknown initial configuration.

Note that this template does not have the usual outputs, as it assumed that the user will get them via interrogating the remote state file instead. To access the outputs in a the classic manner, use the following:

```bash
terraform output -module=pas
```


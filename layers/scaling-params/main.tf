provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

locals {
  defaults = {
    // AL2 VMS
    control-plane = {
      nat         = "t2.medium"
      sjb         = "m4.2xlarge"
      ops-manager = "m4.large"
    }

    pas = {
      nat         = "t2.medium"
      ops-manager = "m4.large"
    }

    isolation-segment = {
      nat = "t2.medium"
    }

    enterprise-services = {
      nat     = "t2.medium"
      bind    = "t2.medium"
      ldap    = "t2.small"
      fluentd = "t2.medium"
      postfix = "t2.medium"
    }

    bastion = {
      bastion = "t2.small"
    }

    // BOSH VMS
    p-bosh = {
      compilation = "automatic"
      director    = "m5.large"
    }

    appMetrics = {
      db-and-errand-runner = "c5.2xlarge"
      log-store-vms        = "r5.large"
    }

    cf = {
      backup_restore                = "t3.medium"
      clock_global                  = "t3.medium"
      cloud_controller              = "m5.large"
      cloud_controller_worker       = "t3.medium"
      credhub                       = "r5.large"
      diego_brain                   = "t3.small"
      diego_cell                    = "r5.large"
      diego_database                = "t3.medium"
      doppler                       = "m5.large"
      loggregator_trafficcontroller = "t3.medium"
      nats                          = "t3.medium"
      router                        = "t3.medium"
      uaa                           = "m5.large"
    }

    metric-store = {
      metric-store = "r5.large"
    }

    p-antivirus-mirror = {
      antivirus-mirror = "c5.large"
    }

    p-compliance-scanner = {
      oscap_store = "c5.large"
    }

    p-healthwatch2 = {
      grafana   = "m5.large"
      pxc       = "m5.large"
      pxc-proxy = "m5.large"
      tsdb      = "r5.large"
    }

    p-healthwatch2-pas-exporter = {
      bosh-deployments-exporter = "t3.medium"
      bosh-health-exporter      = "t3.medium"
      cert-expiration-exporter  = "t3.medium"
      pas-exporter-counter      = "m5.large"
      pas-exporter-gauge        = "m5.xlarge"
      pas-exporter-timer        = "m5.large"
      pas-sli-exporter          = "t3.medium"
    }

    p-isolation-segment = {
      isolated_diego_cell = "r5.large"
    }

    // MARKER
    pws-dark-concourse-tile = {
      credhub = "c5.xlarge"
      uaa     = "c5.xlarge"
      web     = "c5.xlarge"
      worker  = "r5.4xlarge"
    }
  }
}

variable "overrides" {
  type = map(map(string))
}

output "instance_types" {
  value = merge(local.defaults, {for product, types in var.overrides: product => merge(local.defaults[product], types)})
}

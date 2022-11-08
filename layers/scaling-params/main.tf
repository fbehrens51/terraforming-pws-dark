locals {
  defaults = {
    // AL2 VMS
    control-plane = {
      nat         = "t3.medium"
      sjb         = "m5.2xlarge"
      ops-manager = "m5.large"
      r7-console  = "m5.2xlarge"
      r7-engine   = "r5.xlarge"
      scanner     = "t3.xlarge"
      bind        = "t3.medium"
    }

    pas = {
      nat         = "t3.medium"
      ops-manager = "m5.large"
    }

    isolation-segment = {
      nat = "t3.medium"
    }

    enterprise-services = {
      nat     = "t3.medium"
      bind    = "t3.medium"
      fluentd = "t3.medium"
      loki    = "t3.medium"
      postfix = "t3.medium"
    }

    bastion = {
      bastion = "t3.small"
    }

    // BOSH VMS
    p-bosh = {
      compilation = "automatic"
      director    = "m5.xlarge"
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
      diego_brain                   = "t3.medium"
      diego_cell                    = "r5.large"
      diego_database                = "t3.medium"
      doppler                       = "m5.large"
      log_cache                     = "m5.large"
      loggregator_trafficcontroller = "t3.medium"
      nats                          = "t3.medium"
      router                        = "t3.medium"
      uaa                           = "m5.large"
    }

    metric-store = {
      metric-store = "r5.large"
    }

    p-antivirus-mirror = {
      antivirus-mirror = "m5.large"
    }

    p-compliance-scanner = {
      oscap_store = "m5.large"
    }

    p-csb = {
      credhub_service_broker = "t3.medium"
    }

    p-scs = {
      spring-cloud-services = "m5.large"
    }

    p-spring-gateway = {
      spring-gateway = "m5.large"
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
      pas-exporter-gauge        = "m5.large"
      pas-sli-exporter          = "t3.medium"
    }

    p-isolation-segment = {
      isolated_diego_cell = "r5.large"
      router              = "t3.medium"
    }

    pws-dark-concourse-tile = {
      credhub = "m5.large"
      uaa     = "m5.large"
      web     = "m5.large"
      worker  = "r5.xlarge"
    }

    pws-dark-concourse-worker-tile = {
      worker = "r5.xlarge"
    }
  }
}

variable "overrides" {
  type = map(map(string))
}

output "instance_types" {
  value = merge(local.defaults, { for product, types in var.overrides : product => merge(local.defaults[product], types) })
}


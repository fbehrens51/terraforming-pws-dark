variable "env_name" {
  type = string
}

variable "fluentd_role_name" {
}

variable "loki_role_name" {
}

variable "isse_role_name" {
}

variable "instance_tagger_role_name" {
}

variable "director_role_name" {
}

variable "bootstrap_role_name" {
}

variable "foundation_role_name" {
}

variable "bucket_role_name" {
}

variable "worker_role_name" {
}

variable "tsdb_role_name" {
}

variable "om_role_name" {
}

variable "bosh_role_name" {
}

variable "sjb_role_name" {
}

variable "concourse_role_name" {
}

variable "root_domain" {
}

/**
 * TKG Specific
 */

variable "enable_tkg" {
}

variable "tkg_control_plane_role_name" {
  default = "control-plane.tkg.cloud.vmware.com"
}

variable "tkg_nodes_role_name" {
  default = "nodes.tkg.cloud.vmware.com"
}

variable "tkg_controllers_role_name" {
  default = "controllers.tkg.cloud.vmware.com"
}

output "iso_seg_template" {
  value     = module.config.tile_config
  sensitive = true
}

output "placement_tag" {
  value = local.hyphenated_name
}


output "iso_seg_template" {
  value     = "${module.config.tile_config}"
  sensitive = true
}

output "download_iso_seg_base_tile_config" {
  value     = "${module.config.base_tile_download_config}"
  sensitive = true
}

output "download_iso_seg_config" {
  value     = "${module.config.download_config}"
  sensitive = true
}

output "placement_tag" {
  value = "${local.hyphenated_name}"
}

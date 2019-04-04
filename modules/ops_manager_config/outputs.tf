
output "create_db_script_content" {
  value="${data.template_file.create_db.rendered}"
}

output "drop_db_script_content" {
  value="${data.template_file.drop_db.rendered}"
}

output "ops_manager_infra_vars" {
  value="${data.template_file.tile_vars.rendered}"
}

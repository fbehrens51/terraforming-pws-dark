data "aws_iam_role" "ops_manager" {
  name = "${var.ops_manager_role_name}"
}

data "aws_iam_instance_profile" "ops_manager" {
  name = "${var.ops_manager_role_name}"
}

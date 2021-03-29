
resource "aws_iam_role" "ldap" {
  name = "ldap-execution-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.ldap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ldap" {
  role       = aws_iam_role.ldap.name
  policy_arn = aws_iam_policy.ldap.arn
}

resource "aws_iam_policy" "ldap" {
  name   = "ldap_execution_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ldap.json
}

data "aws_iam_policy_document" "ldap" {
  statement {
    sid = "1"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.ldap_password.arn
    ]
  }
}

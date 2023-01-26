##
# Create password for rds master user
##
resource "random_password" "db_password" {
  length  = 30
  lower   = true
  upper   = true
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "db_password" {
  #checkov:skip=CKV_AWS_149
  name                    = "${var.networking[0].application}-db-password"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-db-password"
    },
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

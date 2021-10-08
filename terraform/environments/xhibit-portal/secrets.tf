# # Get secret by name for environment management
# data "aws_secretsmanager_secret" "environment_management" {
#   provider = aws.modernisation-platform
#   name     = "environment_management"
# }

# # Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
# data "aws_secretsmanager_secret_version" "environment_management" {
#   provider  = aws.modernisation-platform
#   secret_id = data.aws_secretsmanager_secret.environment_management.id
# }


data "aws_secretsmanager_secret" "environment_management" {
  arn = "arn:aws:secretsmanager:eu-west-2:946070829339:secret:environment_management-BLRCDb"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}
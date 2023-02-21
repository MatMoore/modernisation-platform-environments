#### Secret for support email address ###
resource "aws_secretsmanager_secret" "support_email_account" {
  name        = "support_email_account"
  description = "email address of the support account for cw alerts"
}

# use a default dummy address just for creation.  Will require to be populated manually
resource "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id     = aws_secretsmanager_secret.support_email_account.id
  secret_string = "default@email.com"
  lifecycle {
    ignore_changes = [secret_string, ]
  }
  depends_on = [
    aws_secretsmanager_secret.support_email_account
  ]

}


#### SNS ####
resource "aws_sns_topic" "cw_alerts" {
  name = "ccms-ebs-ec2-alerts"
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "user_subscription" {
  count     = local.is-production ? 0 : 1
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "email"
  endpoint  = aws_secretsmanager_secret_version.support_email_account.secret_string
  depends_on = [
    aws_secretsmanager_secret_version.support_email_account
  ]
}
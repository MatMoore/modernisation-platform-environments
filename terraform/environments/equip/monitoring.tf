# DDoS Alarm

resource "aws_cloudwatch_metric_alarm" "ddos_attack_external" {
  alarm_name          = "DDoSDetected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.high_priority.arn]
  dimensions = {
    ResourceArn = aws_lb.citrix_alb.arn
  }
}

# SNS topic for monitoring to send alarms to
#tfsec:ignore:aws-sns-topic-encryption-use-cmk
resource "aws_sns_topic" "high_priority" {
  name              = format("%s_high_priority", local.application_name)
  kms_master_key_id = "alias/aws/sns"
}

## Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.high_priority
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.high_priority.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}
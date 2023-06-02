##################################################
# Main
##################################################

resource "aws_mwaa_environment" "main" {
  name                            = local.airflow_name
  airflow_version                 = local.environment_configuration.airflow_version
  environment_class               = local.environment_configuration.airflow_environment_class
  weekly_maintenance_window_start = local.airflow_weekly_maintenance_window_start

  execution_role_arn = module.airflow_execution_role.iam_role_arn

  source_bucket_arn    = module.airflow_s3_bucket.bucket.arn
  dag_s3_path          = local.airflow_dag_s3_path
  requirements_s3_path = local.airflow_requirements_s3_path

  max_workers = local.environment_configuration.airflow_max_workers
  min_workers = local.environment_configuration.airflow_min_workers
  schedulers  = local.environment_configuration.airflow_schedulers

  webserver_access_mode = local.airflow_webserver_access_mode

  # airflow_configuration_options = local.environment_configuration.airflow_configuration_options
  airflow_configuration_options = merge(
    local.environment_configuration.airflow_configuration_options,
    {
      "smtp.smtp_host"                     = "email-smtp.${data.aws_region.current.name}.amazonaws.com"
      "smtp.smtp_port"                     = 587
      "smtp.smtp_starttls"                 = 1
      "smtp.smtp_user"                     = module.airflow_iam_user.iam_access_key_id
      "smtp.smtp_password"                 = module.airflow_iam_user.iam_access_key_ses_smtp_password_v4
      "smtp.smtp_mail_from"                = local.airflow_mail_from_address
    }
  )

  network_configuration {
    security_group_ids = [module.airflow_security_group.security_group_id]
    subnet_ids         = slice(data.aws_subnets.shared-private.ids, 0, 2)
  }

  tags = local.tags
}

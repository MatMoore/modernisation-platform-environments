##################################################
# Airflow
##################################################

module "airflow_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.20.0"

  create_role = true
  role_name   = "data-platform-airflow-execution-role"

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  custom_role_policy_arns = [
    module.airflow_execution_policy.arn
  ]
}

#------------------------------------------------------------------------------
# Common IAM policies for all ec2 instance profiles
#------------------------------------------------------------------------------
# CHECK
# resource "aws_kms_grant" "ssm-start-stop-shared-cmk-grant" {
#   count             = local.environment == "test" ? 1 : 0
#   name              = "image-builder-shared-cmk-grant"
#   key_id            = data.aws_kms_key.hmpps_key.arn
#   grantee_principal = aws_iam_role.ssm_ec2_start_stop.arn
#   operations = [
#     "Encrypt",
#     "Decrypt",
#     "ReEncryptFrom",
#     "GenerateDataKey",
#     "GenerateDataKeyWithoutPlaintext",
#     "DescribeKey",
#     "CreateGrant"
#   ]
# }
# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
# data "aws_iam_policy_document" "ssm_custom" {
#   statement {
#     sid    = "CustomSsmPolicy"
#     effect = "Allow"
#     actions = [
#       "ssm:DescribeAssociation",
#       "ssm:DescribeDocument",
#       "ssm:GetDeployablePatchSnapshotForInstance",
#       "ssm:GetDocument",
#       "ssm:GetManifest",
#       "ssm:ListAssociations",
#       "ssm:ListInstanceAssociations",
#       "ssm:PutInventory",
#       "ssm:PutComplianceItems",
#       "ssm:PutConfigurePackageResult",
#       "ssm:UpdateAssociationStatus",
#       "ssm:UpdateInstanceAssociationStatus",
#       "ssm:UpdateInstanceInformation",
#       "ssmmessages:CreateControlChannel",
#       "ssmmessages:CreateDataChannel",
#       "ssmmessages:OpenControlChannel",
#       "ssmmessages:OpenDataChannel",
#       "ec2messages:AcknowledgeMessage",
#       "ec2messages:DeleteMessage",
#       "ec2messages:FailMessage",
#       "ec2messages:GetEndpoint",
#       "ec2messages:GetMessages",
#       "ec2messages:SendReply"
#     ]
#     # skiping these as policy is a scoped down version of Amazon provided AmazonSSMManagedInstanceCore managed policy.  Permissions required for SSM function

#     #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
#     resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
#   }
# }

# custom policy document for cloudwatch agent, based on CloudWatchAgentServerPolicy but removed CreateLogGroup permission to enforce all log groups in code
data "aws_iam_policy_document" "cloud_watch_custom" {
  statement {
    sid    = "CloudWatchAgentServerPolicy"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream"
    ]
    # skiping these as policy is a scoped down version of Amazon provided CloudWatchAgentServerPolicy managed policy
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }

  statement {
    sid    = "DenyCreateLogGroups"
    effect = "Deny"
    actions = [
      # Letting instances create log groups makes it difficult to delete them later
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AccessCloudWatchConfigParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [aws_ssm_parameter.cloud_watch_config_linux.arn]
  }
}

# create policy document for access to s3 artefact bucket 
#                                                       CHECK THIS LATER
# data "aws_iam_policy_document" "s3_bucket_access" {
#   statement {
#     sid    = "AllowOracleSecureWebListBucketandGetLocation"
#     effect = "Allow"
#     actions = [
#       "s3:ListAllMyBuckets",
#       "s3:GetBucketLocation"
#     ]
#     resources = ["arn:aws:s3:::*"]
#   }
#   statement {
#     sid    = "AccessToInstallationArtefactBucket"
#     effect = "Allow"
#     actions = [
#       "s3:PutObject",
#       "s3:GetObject",
#       "s3:ListBucket",
#       "s3:DeleteObject"
#     ]
#     resources = [module.s3-bucket.bucket.arn,
#     "${module.s3-bucket.bucket.arn}/*"]
#   }

#   statement {
#     sid    = "AccessToAuditAchiveBucket"
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:PutObjectAcl",
#       "s3:ListBucket"
#     ]
#     resources = [
#       module.oasys-audit-archives.bucket.arn,
#       "${module.oasys-audit-archives.bucket.arn}/*"
#     ]
#   }
# }

# combine ec2-common policy documents
# data "aws_iam_policy_document" "ec2_common_combined" {
#   source_policy_documents = [
#     data.aws_iam_policy_document.ssm_custom.json,
#     data.aws_iam_policy_document.s3_bucket_access.json,
#     data.aws_iam_policy_document.cloud_watch_custom.json
#   ]
# }

# create single managed policy
# resource "aws_iam_policy" "ec2_common_policy" {
#   name        = "ec2-common-policy"
#   path        = "/"
#   description = "Common policy for all ec2 instances"
#   policy      = data.aws_iam_policy_document.ec2_common_combined.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "ec2-common-policy"
#     },
#   )
# }

# create list of common managed policies that can be attached to ec2 instance profiles
# locals {
#   ec2_common_managed_policies = [
#     aws_iam_policy.ec2_common_policy.arn
#   ]
# }

#------------------------------------------------------------------------------
# Keypair for ec2-user
#------------------------------------------------------------------------------
# resource "aws_key_pair" "ec2-user" {
#   key_name   = "ec2-user"
#   public_key = local.environment_config.ec2_common.public_key
#   tags = merge(
#     local.tags,
#     {
#       Name = "ec2-user"
#     },
#   )
# }

#------------------------------------------------------------------------------
# Session Manager Logging and Settings
#------------------------------------------------------------------------------

# resource "aws_ssm_document" "session_manager_settings" {
#   name            = "SSM-SessionManagerRunShell"
#   document_type   = "Session"
#   document_format = "JSON"

#   content = jsonencode(
#     {
#       schemaVersion = "1.0"
#       description   = "Document to hold regional settings for Session Manager"
#       sessionType   = "Standard_Stream",
#       inputs = {
#         cloudWatchLogGroupName      = "session-manager-logs"
#         cloudWatchEncryptionEnabled = false
#         cloudWatchStreamingEnabled  = true
#         s3BucketName                = ""
#         s3KeyPrefix                 = ""
#         s3EncryptionEnabled         = false
#         idleSessionTimeout          = "20"
#         kmsKeyId                    = "" # aws_kms_key.session_manager.arn
#         runAsEnabled                = false
#         runAsDefaultUser            = ""
#         shellProfile = {
#           windows = ""
#           linux   = ""
#         }
#       }
#     }
#   )
# }

# commented out for now - see https://mojdt.slack.com/archives/C01A7QK5VM1/p1637603085030600
# resource "aws_kms_key" "session_manager" {
#   enable_key_rotation = true

#   tags = merge(
#     local.tags,
#     {
#       Name = "session_manager"
#     },
#   )
# }

# resource "aws_kms_alias" "session_manager_alias" {
#   name          = "alias/session_manager_key"
#   target_key_id = aws_kms_key.session_manager.arn
# }

#------------------------------------------------------------------------------
# Cloud Watch Log Groups
#------------------------------------------------------------------------------

# Ignore warnings regarding log groups not encrypted using customer-managed
# KMS keys - note they are still encrypted with default KMS key
#tfsec:ignore:AWS089
# resource "aws_cloudwatch_log_group" "groups" {
#   #checkov:skip=CKV_AWS_158:skip KMS CMK encryption check while logging solution is being determined
#   for_each          = local.environment_config.log_groups
#   name              = each.key
#   retention_in_days = each.value.retention_days

#   tags = merge(
#     local.tags,
#     {
#       Name = each.key
#     },
#   )
# }

#------------------------------------------------------------------------------
# Cloud Watch Agent
#------------------------------------------------------------------------------

# resource "aws_ssm_document" "cloud_watch_agent" {
#   name            = "InstallAndManageCloudWatchAgent"
#   document_type   = "Command"
#   document_format = "YAML"
#   content         = file("./ssm-documents/install-and-manage-cwagent.yaml")

#   tags = merge(
#     local.tags,
#     {
#       Name = "install-and-manage-cloud-watch-agent"
#     },
#   )
# }

# resource "aws_ssm_association" "manage_cloud_watch_agent_linux" {
#   name             = aws_ssm_document.cloud_watch_agent.name
#   association_name = "manage-cloud-watch-agent"
#   parameters = { # name of ssm parameter containing cloud watch agent config file
#     optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
#   }
#   targets {
#     key    = "tag:os_type"
#     values = ["Linux"]
#   }
#   apply_only_at_cron_interval = false
#   schedule_expression         = "cron(45 7 ? * TUE *)"
# }

resource "aws_ssm_parameter" "cloud_watch_config_linux" {
  #checkov:skip=CKV2_AWS_34:there should not be anything secret in this config
  description = "cloud watch agent config for linux"
  name        = "cloud-watch-config-linux"
  type        = "String"
  value       = file("./templates/cloud_watch_linux.json")

  tags = merge(
    local.tags,
    {
      Name = "cloud-watch-config-linux"
    },
  )
}

# TODO: config for windows

#------------------------------------------------------------------------------
# SSM Agent - update Systems Manager Agent
#------------------------------------------------------------------------------

# resource "aws_ssm_association" "update_ssm_agent" {
#   name             = "AWS-UpdateSSMAgent" # this is an AWS provided document
#   association_name = "update-ssm-agent"
#   parameters = {
#     allowDowngrade = "false"
#   }
#   targets {
#     # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
#     key    = "tag:os_type"
#     values = ["Linux", "Windows"]
#   }
#   apply_only_at_cron_interval = false
#   schedule_expression         = "cron(30 7 ? * TUE *)"
# }

#------------------------------------------------------------------------------
# Node Exporter - Install/Start Node Exporter Service
#------------------------------------------------------------------------------

# resource "aws_ssm_document" "node_exporter_linux" {
#   name            = "InstallNodeExporterLinux"
#   document_type   = "Command"
#   document_format = "JSON"
#   content         = templatefile("${path.module}/ssm-documents/templates/node-exporter-linux.json.tmpl", { bucket_name = module.s3-bucket.bucket.id })
#   target_type     = "/AWS::EC2::Instance"

#   tags = merge(
#     local.tags,
#     {
#       Name = "install-node-exporter-linux"
#     },
#   )
# }

# resource "aws_ssm_association" "node_exporter_linux" {
#   name             = aws_ssm_document.node_exporter_linux.name
#   association_name = "node-exporter-linux"
#   targets {
#     key    = "tag:os_type"
#     values = ["Linux"]
#   }
# }

# resource "aws_ssm_document" "script_exporter" {
#   name            = "InstallScriptExporterLinux"
#   document_type   = "Command"
#   document_format = "YAML"
#   content         = file("./ssm-documents/install-and-manage-script-exporter.yaml")
#   target_type     = "/AWS::EC2::Instance"

#   tags = merge(
#     local.tags,
#     {
#       Name = "install-and-manage-script-exporter"
#     },
#   )
# }

# resource "aws_ssm_association" "script-exporter" {
#   name             = aws_ssm_document.script_exporter.name
#   association_name = "install-and-manage-script-exporter"
#   targets {
#     key    = "tag-key"
#     values = ["oracle_sids"]
#   }
# }


#------------------------------------------------------------------------------
# Oracle Secure Web - Install Oracle Secure Web s3 Backup Module
#------------------------------------------------------------------------------

# resource "aws_ssm_document" "oracle_secure_web" {
#   name            = "InstallOracleSecureWeb"
#   document_type   = "Command"
#   document_format = "JSON"
#   content         = templatefile("${path.module}/ssm-documents/templates/oracle-secure-web-install.json.tmpl", { bucket_name = module.s3-bucket.bucket.id })
#   target_type     = "/AWS::EC2::Instance"

#   tags = merge(
#     local.tags,
#     {
#       Name = "install-and-test-oracle-secure-web-backup"
#     },
#   )
# }

# resource "aws_ssm_association" "oracle_secure_web" {
#   name             = aws_ssm_document.oracle_secure_web.name
#   association_name = "install-and-test-oracle-secure-web-backup"
#   targets {
#     key    = "tag-key"
#     values = ["oracle_sids"]
#   }
# }


# TODO: Temporarily disable automatic provisioning while performing DR tests.

#------------------------------------------------------------------------------
# Scheduled overnight shutdown
# This is a pretty basic implementation until Mod Platform build a platform
# wide solution.  State Manager does not allow cron expressions like MON-FRI
# so we need to create a separate association for each day in order to deal with
# weekends.  Alternatively we could use Eventbridge rules as a trigger, but its
# slightly more complex to setup the IAM roles for that.
#
# Note that instances created throught the Weblogic module are not in scope as
# they are managed by an autoscaling group, and therefore are not tagged as targets
#------------------------------------------------------------------------------

# locals {
#   weekdays = ["MON", "TUE", "WED", "THU", "FRI"]
# }

# # Scheduled start
# resource "aws_ssm_association" "ec2_scheduled_start" {
#   for_each                         = toset(local.weekdays)
#   name                             = "AWS-StartEC2Instance" # this is an AWS provided document
#   association_name                 = "ec2_scheduled_start_${each.value}"
#   automation_target_parameter_name = "InstanceId"
#   parameters = {
#     AutomationAssumeRole = aws_iam_role.ssm_ec2_start_stop.arn
#   }
#   targets {
#     key    = "tag:always_on"
#     values = ["false"]
#   }
#   apply_only_at_cron_interval = true
#   schedule_expression         = "cron(0 7 ? * ${each.value} *)"
# }

# # Scheduled stop
# resource "aws_ssm_association" "ec2_scheduled_stop" {
#   for_each                         = toset(local.weekdays)
#   name                             = "AWS-StopEC2Instance" # this is an AWS provided document
#   association_name                 = "ec2_scheduled_stop_${each.value}"
#   automation_target_parameter_name = "InstanceId"
#   parameters = {
#     AutomationAssumeRole = aws_iam_role.ssm_ec2_start_stop.arn
#   }
#   targets {
#     key    = "tag:always_on"
#     values = ["false"]
#   }
#   apply_only_at_cron_interval = true
#   schedule_expression         = "cron(0 19 ? * ${each.value} *)"
# }

# data "aws_iam_policy_document" "ssm_ec2_start_stop_kms" {
#   statement {
#     sid    = "manageSharedAMIsEncryptedEBSVolumes"
#     effect = "Allow"
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:ReEncryptFrom",
#       "kms:GenerateDataKey*",
#       "kms:DescribeKey",
#       "kms:CreateGrant",
#       "kms:ListGrants",
#       "kms:RevokeGrant"
#     ]
#     # we have a legacy CMK that's used in production that will be retired but in the meantime requires permissions
#     resources = [local.environment == "test" ? aws_kms_key.oasys-cmk[0].arn : data.aws_kms_key.oasys_key.arn, data.aws_kms_key.hmpps_key.arn]
#   }

#   statement {
#     sid    = "modifyAautoscalingGroupProcesses"
#     effect = "Allow"

#     actions = [
#       "autoscaling:SuspendProcesses",
#       "autoscaling:ResumeProcesses",
#       "autoscaling:DescribeAutoScalingGroups",
#     ]
#     #this role manages all the autoscaling groups in an account
#     #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
#     #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
#     resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
#   }
# }

# resource "aws_iam_role" "ssm_ec2_start_stop" {
#   name                 = "ssm-ec2-start-stop"
#   path                 = "/"
#   max_session_duration = "3600"
#   assume_role_policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Principal" : {
#             "Service" : "ssm.amazonaws.com"
#           }
#           "Action" : "sts:AssumeRole",
#           "Condition" : {}
#         }
#       ]
#     }
#   )
#   managed_policy_arns = [
#     "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
#     # todo: This policy gives a lot of permissions. We should create a custom policy if we keep the solution long term
#   ]
#   inline_policy {

#     name   = "ssm-ec2-start-stop-kms"
#     policy = data.aws_iam_policy_document.ssm_ec2_start_stop_kms.json

#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "ssm-ec2-start-stop"
#     },
#   )
# }


# #------------------------------------------------------------------------------
# # Patch Manager
# #------------------------------------------------------------------------------

# # Define a Maintenance Window, 2am on patch_day, 180 minutes
# resource "aws_ssm_maintenance_window" "maintenance" {
#   name                       = "weekly-patching"
#   description                = "Maintenance window for applying OS patches"
#   schedule                   = "cron(0 2 ? * ${local.environment_config.ec2_common.patch_day} *)"
#   duration                   = 3
#   cutoff                     = 1
#   enabled                    = true
#   allow_unassociated_targets = true
#   tags = merge(
#     local.tags,
#     {
#       Name = "weekly-patching"
#     },
#   )
# }

# # Maintenance window task to start instances in scope of scheduled shutdown
# resource "aws_ssm_maintenance_window_target" "start_instances" {
#   window_id     = aws_ssm_maintenance_window.maintenance.id
#   name          = "start-instances"
#   description   = "Target group for instances in scope of scheduled shutdown"
#   resource_type = "INSTANCE"

#   targets {
#     key    = "tag:always_on"
#     values = ["false"]
#   }
# }

# resource "aws_ssm_maintenance_window_task" "start_instances" {
#   name            = "Start-Instances"
#   description     = "Starts instances that are in scope of scheduled shutdown"
#   max_concurrency = "100%"
#   max_errors      = "100%"
#   cutoff_behavior = "CANCEL_TASK"
#   priority        = 1
#   task_arn        = "AWS-StartEC2Instance"
#   task_type       = "AUTOMATION"
#   window_id       = aws_ssm_maintenance_window.maintenance.id

#   targets {
#     key    = "WindowTargetIds"
#     values = [aws_ssm_maintenance_window_target.start_instances.id]
#   }

#   task_invocation_parameters {
#     automation_parameters {
#       document_version = "$LATEST"
#       parameter {
#         name   = "AutomationAssumeRole"
#         values = [aws_iam_role.ssm_ec2_start_stop.arn]
#       }
#       parameter {
#         name   = "InstanceId"
#         values = ["*"]
#       }
#     }
#   }
# }

# # Maintenance window task to apply RHEL patches
# resource "aws_ssm_maintenance_window_target" "rhel_patching" {
#   window_id     = aws_ssm_maintenance_window.maintenance.id
#   name          = "rhel-patching"
#   description   = "Target group for RHEL patching"
#   resource_type = "INSTANCE"

#   targets {
#     key    = "tag:Patch Group"
#     values = [aws_ssm_patch_group.rhel.patch_group]
#   }
# }

# resource "aws_ssm_maintenance_window_task" "rhel_patching" {
#   name            = "RHEL-security-patching"
#   description     = "Applies AWS default patch baseline for RHEL instances"
#   max_concurrency = "100%"
#   max_errors      = "50%"
#   cutoff_behavior = "CANCEL_TASK"
#   priority        = 2
#   task_arn        = "AWS-RunPatchBaseline"
#   task_type       = "RUN_COMMAND"
#   window_id       = aws_ssm_maintenance_window.maintenance.id

#   targets {
#     key    = "WindowTargetIds"
#     values = [aws_ssm_maintenance_window_target.rhel_patching.id]
#   }

#   task_invocation_parameters {
#     run_command_parameters {
#       parameter {
#         name   = "Operation"
#         values = ["Install"]
#       }
#       parameter {
#         name   = "RebootOption"
#         values = ["NoReboot"]
#       }
#     }
#   }
# }

# # Maintenance window task to apply Windows patches
# resource "aws_ssm_maintenance_window_target" "windows_patching" {
#   window_id     = aws_ssm_maintenance_window.maintenance.id
#   name          = "windows-patching"
#   description   = "Target group for Windows patching"
#   resource_type = "INSTANCE"

#   targets {
#     key    = "tag:Patch Group"
#     values = [aws_ssm_patch_group.windows.patch_group]
#   }
# }

# resource "aws_ssm_maintenance_window_task" "windows_patching" {
#   name            = "Windows-security-patching"
#   description     = "Applies AWS default patch baseline for Windows instances"
#   max_concurrency = "100%"
#   max_errors      = "50%"
#   cutoff_behavior = "CANCEL_TASK"
#   priority        = 2
#   task_arn        = "AWS-RunPatchBaseline"
#   task_type       = "RUN_COMMAND"
#   window_id       = aws_ssm_maintenance_window.maintenance.id

#   targets {
#     key    = "WindowTargetIds"
#     values = [aws_ssm_maintenance_window_target.windows_patching.id]
#   }

#   task_invocation_parameters {
#     run_command_parameters {
#       parameter {
#         name   = "Operation"
#         values = ["Install"]
#       }
#       parameter {
#         name   = "RebootOption"
#         values = ["RebootIfNeeded"]
#       }
#     }
#   }
# }

# # Patch Baselines
# resource "aws_ssm_patch_baseline" "rhel" {
#   name             = "USER-RedHatPatchBaseline"
#   description      = "Approves all RHEL operating system patches that are classified as Security and Bugfix and that have a severity of Critical or Important."
#   operating_system = "REDHAT_ENTERPRISE_LINUX"

#   approval_rule {
#     approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
#     compliance_level   = "CRITICAL"
#     patch_filter {
#       key    = "CLASSIFICATION"
#       values = ["Security"]
#     }
#     patch_filter {
#       key    = "SEVERITY"
#       values = ["Critical"]
#     }
#   }

#   approval_rule {
#     approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
#     compliance_level   = "HIGH"
#     patch_filter {
#       key    = "CLASSIFICATION"
#       values = ["Security"]
#     }
#     patch_filter {
#       key    = "SEVERITY"
#       values = ["Important"]
#     }
#   }

#   approval_rule {
#     approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
#     compliance_level   = "MEDIUM"
#     patch_filter {
#       key    = "CLASSIFICATION"
#       values = ["Bugfix"]
#     }
#   }
#   tags = merge(
#     local.tags,
#     {
#       Name = "rhel-patch-baseline"
#     },
#   )
# }

# resource "aws_ssm_patch_baseline" "windows" {
#   name             = "USER-WindowsPatchBaseline-OS"
#   description      = "Approves all Windows Server operating system patches that are classified as CriticalUpdates or SecurityUpdates and that have an MSRC severity of Critical or Important."
#   operating_system = "WINDOWS"

#   approval_rule {
#     approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
#     compliance_level   = "CRITICAL"
#     patch_filter {
#       key    = "CLASSIFICATION"
#       values = ["CriticalUpdates", "SecurityUpdates"]
#     }
#     patch_filter {
#       key    = "MSRC_SEVERITY"
#       values = ["Critical"]
#     }
#   }

#   approval_rule {
#     approve_after_days = local.environment_config.ec2_common.patch_approval_delay_days
#     compliance_level   = "HIGH"
#     patch_filter {
#       key    = "CLASSIFICATION"
#       values = ["CriticalUpdates", "SecurityUpdates"]
#     }
#     patch_filter {
#       key    = "MSRC_SEVERITY"
#       values = ["Important"]
#     }
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "windows-patch-baseline"
#     },
#   )
# }

# # Patch Groups
# resource "aws_ssm_patch_group" "rhel" {
#   baseline_id = aws_ssm_patch_baseline.rhel.id
#   patch_group = "RHEL"
# }

# resource "aws_ssm_patch_group" "windows" {
#   baseline_id = aws_ssm_patch_baseline.windows.id
#   patch_group = "Windows"
# }
# # CloudWatch Monitoring Role and Policies

# data "aws_iam_policy_document" "cloud-platform-monitoring-assume-role" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::754256621582:root"]  # cloud-platform-aws account
#     }
#   }
# }

# resource "aws_iam_role" "cloudwatch-datasource-role" {
#   name               = "CloudwatchDatasourceRole"
#   assume_role_policy = data.aws_iam_policy_document.cloud-platform-monitoring-assume-role.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "cloudwatch-datasource-role"
#     },
#   )

# }

# data "aws_iam_policy_document" "cloudwatch_datasource" {
#   statement {
#     sid    = "AllowReadingMetricsFromCloudWatch"
#     effect = "Allow"
#     actions = [
#       "cloudwatch:DescribeAlarmsForMetric",
#       "cloudwatch:DescribeAlarmHistory",
#       "cloudwatch:DescribeAlarms",
#       "cloudwatch:ListMetrics",
#       "cloudwatch:GetMetricData",
#       "cloudwatch:GetInsightRuleReport"
#     ]
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingLogsFromCloudWatch"
#     effect = "Allow"
#     actions = [
#       "logs:DescribeLogGroups",
#       "logs:GetLogGroupFields",
#       "logs:StartQuery",
#       "logs:StopQuery",
#       "logs:GetQueryResults",
#       "logs:GetLogEvents"
#     ]
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingTagsInstancesRegionsFromEC2"
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeTags",
#       "ec2:DescribeInstances",
#       "ec2:DescribeRegions"
#     ]
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingResourcesForTags"
#     effect = "Allow"
#     actions = [
#       "tag:GetResources"
#     ]
#     resources = ["*"]
#   }

# }

# resource "aws_iam_policy" "cloudwatch_datasource_policy" {
#   name        = "cloudwatch-datasource-policy"
#   path        = "/"
#   description = "Policy for the Monitoring Cloudwatch Datasource"
#   policy      = data.aws_iam_policy_document.cloudwatch_datasource.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "cloudwatch-datasource-policy"
#     },
#   )
# }

# resource "aws_iam_role_policy_attachment" "cloudwatch_datasource_policy_attach" {
#   policy_arn = aws_iam_policy.cloudwatch_datasource_policy.arn
#   role       = aws_iam_role.cloudwatch-datasource-role.name

# }

# resource "aws_iam_role" "prometheus-ec2-discovery-role" {
#   name               = "PrometheusEC2DiscoveryRole"
#   assume_role_policy = data.aws_iam_policy_document.cloud-platform-monitoring-assume-role.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "prometheus-ec2-discovery-role"
#     },
#   )
# }

# resource "aws_iam_role_policy_attachment" "prometheus_ec2_discovery_policy_attach" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
#   role       = aws_iam_role.prometheus-ec2-discovery-role.name

# }
variable "iam_role_arn" {
  type        = "arn:aws:iam::711138931639:role/AWSBackup"
  description = "IAM role ARN for the AWS Backup service role"
}

variable "tags" {
  default     = {}
  description = "Tags to apply to resources, where applicable"
  type        = map(any)
}
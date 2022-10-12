variable "account_number" {
  type        = string
  description = "Account number of current environment"
}
variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}
variable "application_name" {
  type        = string
  description = "Name of application"
}
variable "public_subnets" {
  type        = list(string)
  description = "Public subnets"
}
variable "loadbalancer_ingress_rules" {
  description = "Security group ingress rules for the loadbalancer"
  type = map(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = list(string)
    cidr_blocks     = list(string)
  }))
}

variable "loadbalancer_egress_rules" {
  description = "Security group egress rules for the loadbalancer"
  type = map(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = list(string)
    cidr_blocks     = list(string)
  }))
}
variable "vpc_all" {
  type        = string
  description = "The full name of the VPC (including environment) used to create resources"
}
variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
}
variable "region" {
  type        = string
  description = "AWS Region where resources are to be created"
}
variable "idle_timeout" {
  type        = string
  description = "The time in seconds that the connection is allowed to be idle."
}
variable "force_destroy_bucket" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
variable "port" {
  type        = string
  description = "The port number for the ALB Listener"
}
variable "protocol" {
  type        = string
  description = "The protocol for the ALB Listener"
}
variable "vpc_id" {
  type        = string
  description = "The id for the VPC"
}
variable "deregistration_delay" {
  type        = string
  description = "The time in seconds for the deregistration delay"
}
variable "health_check.interval" {
  type        = string
  description = "The time in seconds for the health check interval"
}
variable "health_check.protocol" {
  type        = string
  description = "The protocol for the health check"
}
variable "health_check.timeout" {
  type        = string
  description = "The tiomeout in seconds for the health check"
}
variable "health_check.healthy_threshold" {
  type        = string
  description = "The healthy threshold in seconds for the health check"
}
variable "health_check.unhealthy_threshold" {
  type        = string
  description = "The unhealthy threshold in seconds for the health check"
}
variable "stickiness.enabled" {
  type        = bool
  description = "The enabled setting for the stickiness"
}
variable "stickiness.type" {
  type        = string
  description = "The type setting for the stickiness"
}
variable "stickiness.cookie_duration" {
  type        = string
  description = "The cookie duration in seconds for the stickiness"
}
variable "ingress_cidr_block" {
  type        = string
  description = "The cidr block for the lb ingress rules"
}




























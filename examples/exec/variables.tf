variable "deployer_role_arn" {
  description = "A role with the permissions the commands need. Only the apply pipeline should be able to assume it."
  type        = string
  default     = "arn:aws:iam::123456789012:role/Deployer"
}

variable "log_group_name" {
  description = "The log group to create."
  type        = string
  default     = "/app/example"
}

variable "retention_in_days" {
  description = "How long to keep log events."
  type        = number
  default     = 30
}

variable "reader_role_arn" {
  description = "A role with read-only permissions to assume for the query."
  type        = string
  default     = "arn:aws:iam::123456789012:role/ReadOnly"
}

variable "auto_scaling_group_name" {
  description = "The auto scaling group to inspect."
  type        = string
  default     = "example-asg"
}

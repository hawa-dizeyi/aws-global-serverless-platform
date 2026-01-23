variable "name_prefix" {
  type        = string
  description = "Name prefix for resources."
}

variable "function_suffix" {
  type        = string
  description = "Suffix for function name, e.g. api-primary"
}

variable "table_name" {
  type        = string
  description = "DynamoDB table name."
}

variable "role_arn" {
  type        = string
  description = "IAM role ARN for the Lambda execution role."
}

variable "source_dir" {
  type        = string
  description = "Directory containing Lambda source code."
}

variable "handler" {
  type        = string
  description = "Lambda handler."
  default     = "app.handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime."
  default     = "python3.12"
}

variable "timeout" {
  type        = number
  default     = 10
}

variable "memory_size" {
  type        = number
  default     = 128
}

variable "log_retention_days" {
  type        = number
  default     = 3
}

variable "reserved_concurrency" {
  type        = number
  default     = null
  nullable    = true
  description = "Reserved concurrency. Leave null to avoid account unreserved concurrency constraint."
}

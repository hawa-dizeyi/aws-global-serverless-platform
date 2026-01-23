variable "name_prefix" {
  type        = string
  description = "Name prefix for resources."
}

variable "table_name" {
  type        = string
  description = "Base DynamoDB table name (without prefix)."
  default     = "app"
}

variable "primary_region" {
  type        = string
  description = "Primary region for the table."
}

variable "secondary_region" {
  type        = string
  description = "Secondary region for the replica."
}

variable "hash_key" {
  type        = string
  description = "Partition key name."
  default     = "pk"
}

variable "range_key" {
  type        = string
  description = "Sort key name."
  default     = "sk"
}

variable "ttl_attribute_name" {
  type        = string
  description = "TTL attribute name."
  default     = "ttl"
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Enable PITR (adds cost, improves durability)."
  default     = false
}

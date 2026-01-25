variable "name_prefix" {
  type = string
}

variable "root_domain" {
  type = string
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for the root domain"
}

variable "site_dir" {
  type        = string
  description = "Path to static site directory"
}

variable "enable" {
  type    = bool
  default = false
}

variable "enabled" {
  type        = bool
  description = "Enable frontend resources (S3 + CloudFront)."
  default     = false
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name used by Terraform."
  default     = "serverless-admin"
}

variable "project_name" {
  type        = string
  default     = "project-02-global-serverless"
  description = "Project name for tagging and naming."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name."
}

variable "primary_region" {
  type        = string
  default     = "eu-west-1"
  description = "Primary AWS region (Ireland)."
}

variable "secondary_region" {
  type        = string
  default     = "eu-central-1"
  description = "Secondary AWS region (Frankfurt)."
}

# Feature flags (keep off by default; enable only for demos)
variable "enable_cloudfront" {
  type        = bool
  default     = false
  description = "Enable CloudFront distribution."
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Enable WAF (only meaningful with CloudFront)."
}

variable "enable_r53_health_checks" {
  type        = bool
  default     = false
  description = "Enable Route 53 health checks (may cost monthly)."
}

variable "root_domain" {
  type        = string
  description = "Public domain you own (managed in Route 53)."
  default     = "hawser-labs.online"
}

variable "api_subdomain" {
  type        = string
  description = "Subdomain for the API."
  default     = "api"
}

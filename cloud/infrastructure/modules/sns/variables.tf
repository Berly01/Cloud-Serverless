# ============================================================================
# SNS Module - Alert System
# ============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "alert_email" {
  description = "Email address for receiving critical alerts"
  type        = string
  default     = ""
}

variable "alert_phone" {
  description = "Phone number for receiving SMS alerts (E.164 format)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

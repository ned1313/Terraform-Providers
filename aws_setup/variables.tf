variable "cross_account_role_name" {
  description = "Name of the cross-account role to be assumed"
  type        = string
  default     = "VPCPeeringCrossAccountRole"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]*$", var.cross_account_role_name))
    error_message = "Role name must start with a letter and can contain alphanumeric characters and these special characters: _+=,.@-"
  }
}

variable "primary_user_name" {
  description = "Name of the existing IAM user in the primary account who will assume the cross-account role"
  type        = string
  default     = "vpc-peering-user"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]*$", var.primary_user_name))
    error_message = "User name must start with a letter and can contain alphanumeric characters and these special characters: _+=,.@-"
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

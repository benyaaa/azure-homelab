variable "subscription_id" {
  description = "Your Azure subscription ID (az account show --query id -o tsv)."
  type        = string
}

variable "alert_email" {
  description = "Where budget alerts are sent."
  type        = string
}

variable "owner" {
  description = "Tag value identifying you."
  type        = string
  default     = "me"
}

variable "location" {
  description = "Default region. West Europe or France Central are close to Paris/Brussels."
  type        = string
  default     = "westeurope"
}

variable "monthly_budget" {
  description = "Monthly budget amount in your billing currency."
  type        = number
  default     = 25
}

variable "budget_start_date" {
  description = "First day of the current month, RFC3339 (e.g. 2026-10-01T00:00:00Z)."
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "allowed_locations" {
  description = "Regions where resources may be created."
  type        = list(string)
  default     = ["westeurope", "francecentral"]
}

variable "allowed_vm_skus" {
  description = "Small VM sizes only. Covers Databricks cluster nodes too. Add sizes deliberately."
  type        = list(string)
  default = [
    "Standard_D4ds_v5",
    "Standard_D4ds_v4",
    "Standard_D4as_v5",
    "Standard_DS3_v2",
    "Standard_F4s_v2",
    "Standard_E4ds_v5",
  ]
}

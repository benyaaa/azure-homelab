variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "owner" {
  type    = string
  default = "me"
}

variable "enable_databricks" {
  description = "Create the Azure Databricks workspace. Set false for ADF/ADLS-only sessions."
  type        = bool
  default     = true
}

variable "lake_containers" {
  description = "ADLS Gen2 filesystems for the medallion layout."
  type        = list(string)
  default     = ["landing", "bronze", "silver", "gold"]
}

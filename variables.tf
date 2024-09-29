variable "prefix" {
  description = "A prefix used for all resources in this example"
  default     = "geia"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "sql_admin_username" {
  description = "The administrator username of the SQL Server."
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "The administrator password of the SQL Server."
  sensitive   = true
}

variable "alert_email" {
  description = "Email address for budget alerts"
  type        = string
}
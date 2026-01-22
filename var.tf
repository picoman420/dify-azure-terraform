variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  # No default - must be provided explicitly
}

variable "region" {
  type    = string
  default = "southeastasia"
}

variable "ip_prefix" {
  type    = string
  default = "10.99"
}

variable "dify-api-image" {
  type    = string
  default = "langgenius/dify-api:1.4.1"
}

variable "dify-plugindaemon-image" {
  type    = string
  default = "langgenius/dify-plugin-daemon:0.1.1-local"
}

variable "dify-sandbox-image" {
  type    = string
  default = "langgenius/dify-sandbox:0.2.12"
}

variable "dify-web-image" {
  type    = string
  default = "langgenius/dify-web:1.4.1"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "rg-dify"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account (must be globally unique, 3-24 chars, lowercase alphanumeric)"
  default     = null
}

variable "postgres_admin_password" {
  type        = string
  description = "PostgreSQL administrator password (should be provided via Key Vault)"
  sensitive   = true
  # No default - must be provided explicitly
}

variable "nginx_image" {
  type        = string
  description = "Nginx container image"
  default     = "nginx:1.27-alpine"
}

variable "squid_image" {
  type        = string
  description = "Squid proxy container image"
  default     = "ubuntu/squid:5.2-22.04_beta"
}

variable "dify-api-secret-key" {
  type        = string
  description = "Secret key for Dify API (should be provided via environment variable or Key Vault)"
  sensitive   = true
  # No default - must be provided explicitly
}
# Optional: Azure Key Vault for secret management
# If key_vault_name is provided, secrets will be stored/retrieved from Key Vault
# Otherwise, secrets should be provided via variables

variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault (optional - if not provided, secrets must be passed via variables)"
  default     = null
}

variable "key_vault_create" {
  type        = bool
  description = "Whether to create a new Key Vault (if key_vault_name is provided)"
  default     = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "secrets" {
  count                       = var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }
}

# Store secrets in Key Vault if it's being used
resource "azurerm_key_vault_secret" "postgres_password" {
  count        = var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name         = "postgres-admin-password"
  value        = var.postgres_admin_password
  key_vault_id = azurerm_key_vault.secrets[0].id
}

resource "azurerm_key_vault_secret" "dify_api_secret_key" {
  count        = var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name         = "dify-api-secret-key"
  value        = var["dify-api-secret-key"]
  key_vault_id = azurerm_key_vault.secrets[0].id
}

# Data source to retrieve secrets from existing Key Vault
data "azurerm_key_vault" "existing" {
  count               = !var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "postgres_password" {
  count        = !var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name         = "postgres-admin-password"
  key_vault_id = data.azurerm_key_vault.existing[0].id
}

data "azurerm_key_vault_secret" "dify_api_secret_key" {
  count        = !var.key_vault_create && var.key_vault_name != null ? 1 : 0
  name         = "dify-api-secret-key"
  key_vault_id = data.azurerm_key_vault.existing[0].id
}

# Local values to use Key Vault secrets if available, otherwise use variables
locals {
  postgres_password = var.key_vault_name != null ? (
    var.key_vault_create ? azurerm_key_vault_secret.postgres_password[0].value : data.azurerm_key_vault_secret.postgres_password[0].value
  ) : var.postgres_admin_password

  dify_api_secret_key = var.key_vault_name != null ? (
    var.key_vault_create ? azurerm_key_vault_secret.dify_api_secret_key[0].value : data.azurerm_key_vault_secret.dify_api_secret_key[0].value
  ) : var["dify-api-secret-key"]
}

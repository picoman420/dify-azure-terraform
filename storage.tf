resource "random_id" "storage_suffix" {
  byte_length = 4
}

locals {
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "sadify${random_id.storage_suffix.hex}"
}

resource "azurerm_storage_account" "aca_storage" {
  name                     = substr(replace(lower(local.storage_account_name), "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "dify_fileshare" {
  storage_account_id    = azurerm_storage_account.aca_storage.id
  name                  = "dify-fileshare"
  container_access_type = "private"
}

resource "azurerm_storage_container" "dify_data" {
  storage_account_id    = azurerm_storage_account.aca_storage.id
  name                  = "dify-data"
  container_access_type = "private"
}

module "fileshare_nginx_conf" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/nginx/conf"
  share_name         = "nginx-conf"
}

module "fileshare_nginx_entrypoint" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/nginx/entrypoint"
  share_name         = "nginx-entrypoint"
}

module "fileshare_api_storage" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/api/storage"
  share_name         = "api-storage"
}

module "fileshare_plugindaemon_storage" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/plugin_daemon/storage"
  share_name         = "plugindaemon-storage"
}

module "fileshare_sandbox_conf" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/sandbox/conf"
  share_name         = "sandbox-conf"
}

module "fileshare_sandbox_dependencies" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/sandbox/dependencies"
  share_name         = "sandbox-dependencies"
}

module "fileshare_ssrfproxy_conf" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/ssrf_proxy/conf"
  share_name         = "ssrfproxy-conf"
}

module "fileshare_ssrfproxy_entrypoint" {
  source             = "./modules/fileshare"
  storage_account_id = azurerm_storage_account.aca_storage.id
  local_mount_dir    = "volumes/ssrf_proxy/entrypoint"
  share_name         = "ssrfproxy-entrypoint"
}
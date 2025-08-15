resource "azurerm_resource_group" "rg" {
  name     = "rg-dify"
  location = var.region
}

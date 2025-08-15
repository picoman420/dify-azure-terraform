resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dify-${var.region}"
  address_space       = ["${var.ip_prefix}.0.0/16"]
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "private_link" {
  name                 = "snet-dify-${var.region}-private-link"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.ip_prefix}.1.0/24"]
}

resource "azurerm_subnet" "aca" {
  name                 = "snet-dify-${var.region}-aca"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.ip_prefix}.16.0/20"]

  # サブネットの委任によって、Azure Container Apps がこのサブネットを使用できるようにする
  delegation {
    name = "aca-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-dify-${var.region}-postgres"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.ip_prefix}.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  # サブネットの委任によって、PostgreSQL Flexible Server がこのサブネットを使用できるようにする
  delegation {
    name = "postgres-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}



terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.2.0"
    }
  }
  required_version = ">=1.1.0"
}

provider "azurerm" {
  features {}
}

// Hub network resource group
resource "azurerm_resource_group" "rg-net-lovable1-neu" {
  name     = "rg-net-lovable1-neu"
  location = "northeurope"
}

// Traditional hub VNet
resource "azurerm_virtual_network" "vnet-lovable1-neu" {
  name                = "vnet-lovable1-neu"
  address_space       = ["10.20.0.0/22"]
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
}

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg-net-lovable1-neu.name
  virtual_network_name = azurerm_virtual_network.vnet-lovable1-neu.name
  address_prefixes     = ["10.20.0.0/26"]
}

// Important: how to get firewall public IP address; destination_address = "20.73.77.222"
// Azure Firewall Policy in Hub-WE : premium
resource "azurerm_firewall_policy" "afwpol-lovable1-neu" {
  name                = "afwpol-lovable1-neu"
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  sku                 = "Standard"
}

resource "azurerm_public_ip" "pip-afw-lovable1-neu" {
  name                = "pip-afw-lovable1-neu"
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  lifecycle {
    ignore_changes = [ip_tags]
  }
}

// Azure Firewall in the traditional hub VNet
resource "azurerm_firewall" "afw-lovable1-neu" {
  name                = "afw-lovable1-neu"
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones               = ["1", "2", "3"]
  firewall_policy_id  = azurerm_firewall_policy.afwpol-lovable1-neu.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pip-afw-lovable1-neu.id
  }
}

// Bastion subnet in the hub VNet
resource "azurerm_subnet" "vnet-AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-net-lovable1-neu.name
  virtual_network_name = azurerm_virtual_network.vnet-lovable1-neu.name
  address_prefixes     = ["10.20.2.0/25"]
}

// AKS cluster subnet
resource "azurerm_subnet" "snet-aks-lovable1-neu" {
  name                 = "snet-aks-lovable1-neu"
  resource_group_name  = azurerm_resource_group.rg-net-lovable1-neu.name
  virtual_network_name = azurerm_virtual_network.vnet-lovable1-neu.name
  address_prefixes     = ["10.20.1.0/26"]
}

// Route table for the AKS subnet: default route sends all egress via the Azure Firewall
resource "azurerm_route_table" "rt-aks-lovable1-neu" {
  name                = "rt-aks-lovable1-neu"
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.afw-lovable1-neu.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "rt-aks-assoc" {
  subnet_id      = azurerm_subnet.snet-aks-lovable1-neu.id
  route_table_id = azurerm_route_table.rt-aks-lovable1-neu.id
}

/*
resource "azurerm_public_ip" "pip-bas-lovable1-neu" {
  name                = "pip-bas-lovable1-neu"
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
*/

/*
resource "azurerm_bastion_host" "bas-lovable1-neu" {
  name                = "bas-lovable1-neu"
  location            = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name = azurerm_resource_group.rg-net-lovable1-neu.name
  sku                 = "Standard"
  ip_connect_enabled  = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.vnet-AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.pip-bas-lovable1-neu.id
  }
}
*/


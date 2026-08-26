// Existing VNet outside this Terraform config, peered with the hub VNet
data "azurerm_virtual_network" "vnet-neu" {
  name                = "vnet-neu"
  resource_group_name = "rg-net-neu"
}

// Peering: vnet-lovable1-neu -> vnet-neu
resource "azurerm_virtual_network_peering" "lovable1-to-neu" {
  name                         = "peer-lovable1-neu-to-neu"
  resource_group_name          = azurerm_resource_group.rg-net-lovable1-neu.name
  virtual_network_name         = azurerm_virtual_network.vnet-lovable1-neu.name
  remote_virtual_network_id    = data.azurerm_virtual_network.vnet-neu.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

// Peering: vnet-neu -> vnet-lovable1-neu
resource "azurerm_virtual_network_peering" "neu-to-lovable1" {
  name                         = "peer-neu-to-lovable1-neu"
  resource_group_name          = data.azurerm_virtual_network.vnet-neu.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.vnet-neu.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-lovable1-neu.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

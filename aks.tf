// Private AKS cluster deployed into the AKS subnet of the hub VNet
resource "azurerm_kubernetes_cluster" "aks-lovable1-neu" {
  name                    = "aks-lovable1-neu"
  location                = azurerm_resource_group.rg-net-lovable1-neu.location
  resource_group_name     = azurerm_resource_group.rg-net-lovable1-neu.name
  dns_prefix              = "aks-lovable1-neu"
  private_cluster_enabled = true

  depends_on = [
    azurerm_subnet_route_table_association.rt-aks-assoc,
    azurerm_firewall_policy_rule_collection_group.aks-rules,
  ]

  default_node_pool {
    name           = "system"
    vm_size        = "Standard_B2s" // smallest burstable SKU: 2 vCPU, 4 GB RAM
    node_count     = 1
    vnet_subnet_id = azurerm_subnet.snet-aks-lovable1-neu.id
  }

  identity {
    type = "SystemAssigned"
  }

  node_provisioning_profile {
    mode = "Manual" // node pools are managed explicitly (default_node_pool), not AKS-automatic provisioning
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay" // keeps pod IPs off the /26 subnet, avoiding IP exhaustion
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
    outbound_type       = "userDefinedRouting" // egress forced through the route table's default route via the firewall
  }
}

// Cluster's system-assigned identity needs Network Contributor on its subnet
// to manage NICs/IP configurations for nodes in the custom VNet.
resource "azurerm_role_assignment" "aks-subnet-network-contributor" {
  scope                = azurerm_subnet.snet-aks-lovable1-neu.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks-lovable1-neu.identity[0].principal_id
}

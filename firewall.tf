// AKS required outbound rules: https://learn.microsoft.com/azure/aks/outbound-rules-control-egress
resource "azurerm_firewall_policy_rule_collection_group" "aks-rules" {
  name                = "aks-rules"
  firewall_policy_id  = azurerm_firewall_policy.afwpol-lovable1-neu.id
  priority            = 200

  application_rule_collection {
    name     = "aks-application-rules"
    priority = 200
    action   = "Allow"

    rule {
      name                   = "AKS-fqdn"
      source_addresses       = ["*"]
      destination_fqdn_tags  = ["AzureKubernetesService"]

      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "aks-network-rules"
    priority = 300
    action   = "Allow"

    rule {
      name                  = "AKS-apitcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.NorthEurope"]
      destination_ports     = ["9000"]
    }

    rule {
      name                  = "AKS-apiudp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.NorthEurope"]
      destination_ports     = ["1194"]
    }

    rule {
      name              = "AKS-time"
      protocols         = ["UDP"]
      source_addresses  = ["*"]
      destination_fqdns = ["ntp.ubuntu.com"]
      destination_ports = ["123"]
    }

    rule {
      name              = "AKS-ghcr"
      protocols         = ["TCP"]
      source_addresses  = ["*"]
      destination_fqdns = ["ghcr.io", "pkg-containers.githubusercontent.com"]
      destination_ports = ["443"]
    }

    rule {
      name              = "AKS-docker"
      protocols         = ["TCP"]
      source_addresses  = ["*"]
      destination_fqdns = ["docker.io", "registry-1.docker.io", "production.cloudflare.docker.com"]
      destination_ports = ["443"]
    }
  }
}

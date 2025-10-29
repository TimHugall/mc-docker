terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source to reference existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source to reference existing virtual machine
data "azurerm_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Data source to reference existing Network Security Group
data "azurerm_network_security_group" "main" {
  name                = var.nsg_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Fetch the Azure IP Ranges and Service Tags JSON from Microsoft
# This is updated weekly by Microsoft
# To get the latest URL, visit: https://www.microsoft.com/en-us/download/details.aspx?id=56519
# and update the azure_ip_ranges_url variable
data "http" "azure_ip_ranges" {
  url = var.azure_ip_ranges_url

  request_headers = {
    Accept = "application/json"
  }
}

# Parse the JSON to extract IP prefixes for Australia East and Australia Southeast
locals {
  azure_ip_data = jsondecode(data.http.azure_ip_ranges.response_body)

  # Find the Australia East region IP prefixes
  australia_east = [
    for service in local.azure_ip_data.values : service
    if service.name == "AzureCloud.australiaeast"
  ]

  # Find the Australia Southeast region IP prefixes
  australia_southeast = [
    for service in local.azure_ip_data.values : service
    if service.name == "AzureCloud.australiasoutheast"
  ]

  # Combine all East Coast Australia IP prefixes
  # Note: This represents Azure infrastructure in these regions, not all AU east coast IPs
  # For a more comprehensive solution, you might want to use GeoIP databases
  east_coast_au_prefixes = concat(
    length(local.australia_east) > 0 ? local.australia_east[0].properties.addressPrefixes : [],
    length(local.australia_southeast) > 0 ? local.australia_southeast[0].properties.addressPrefixes : []
  )

  # Create a flattened list of rules (port + IP prefix combinations)
  # We need to create separate rules as Azure NSG doesn't support multiple source prefixes in a single rule easily
  nsg_rules = flatten([
    for port_idx, port in var.allowed_ports : [
      for prefix_idx, prefix in local.east_coast_au_prefixes : {
        name          = "Allow-${port}-from-AU-East-${port_idx}-${prefix_idx}"
        priority      = var.rule_priority_start + (port_idx * 1000) + prefix_idx
        port          = port
        source_prefix = prefix
      }
    ]
  ])
}

# Create NSG rules to allow traffic from East Coast Australia IPs
# Note: Azure NSG has a limit on number of rules (typically 1000 per NSG)
# The Azure IP ranges can contain hundreds of prefixes, so we create individual rules
resource "azurerm_network_security_rule" "allow_east_coast_au" {
  for_each = { for rule in local.nsg_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(each.value.port)
  source_address_prefix       = each.value.source_prefix
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.main.name
  network_security_group_name = data.azurerm_network_security_group.main.name
  description                 = "Allow port ${each.value.port} from East Coast Australia IP ranges - Auto-generated, update regularly"
}

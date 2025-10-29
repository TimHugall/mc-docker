terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "oci" {
  # Authentication is typically done via:
  # - Config file (~/.oci/config)
  # - Environment variables
  # - Instance principal (when running on OCI compute)
}

# Data source to reference existing compartment
data "oci_identity_compartment" "main" {
  id = var.compartment_id
}

# Data source to reference existing compute instance
data "oci_core_instance" "main" {
  instance_id = var.instance_id
}

# Data source to reference existing Network Security Group
data "oci_core_network_security_group" "main" {
  network_security_group_id = var.nsg_id
}

# Fetch IP ranges for East Coast Australia
# Oracle doesn't provide a similar service tags JSON like Azure/AWS
# Instead, we'll use a GeoIP-based approach with publicly available IP ranges
# This fetches Australia IP ranges from a reliable source
data "http" "australia_ip_ranges" {
  url = "https://stat.ripe.net/data/country-resource-list/data.json?resource=AU&v4_format=prefix"

  request_headers = {
    Accept = "application/json"
  }
}

# Parse the JSON to extract IP prefixes for Australia
# Note: This includes ALL of Australia, not just the east coast
# For more precise geo-filtering, you may need to use commercial GeoIP services
locals {
  australia_ip_data = jsondecode(data.http.australia_ip_ranges.response_body)

  # Extract IPv4 prefixes for Australia
  australia_prefixes = try(local.australia_ip_data.data.resources.ipv4, [])

  # For more precise filtering to East Coast Australia, you could:
  # 1. Use a commercial GeoIP database
  # 2. Manually specify known ISP ranges for Sydney/Melbourne/Brisbane
  # 3. Use Oracle's Cloud Guard with geographic restrictions
  # This configuration uses all Australian IPs as a starting point
  east_coast_au_prefixes = local.australia_prefixes

  # Create security rules for each port and IP prefix combination
  # OCI NSGs support multiple rules, similar to Azure
  security_rules = flatten([
    for port_idx, port in var.allowed_ports : [
      for prefix_idx, prefix in local.east_coast_au_prefixes : {
        description = "Allow port ${port} from AU IP ${prefix_idx}"
        source      = prefix
        protocol    = "6" # TCP
        port        = port
        rule_id     = "${port_idx}-${prefix_idx}"
      }
    ]
  ])
}

# Create NSG security rules to allow traffic from Australia IPs
# Note: OCI NSGs have different limits than Azure (check current OCI documentation)
resource "oci_core_network_security_group_security_rule" "allow_east_coast_au" {
  for_each = { for rule in local.security_rules : rule.rule_id => rule }

  network_security_group_id = data.oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source                    = each.value.source
  source_type               = "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port
        max = each.value.port
      }
    }
  }
}

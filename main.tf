terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  # Authentication is typically done via:
  # - Config file (~/.oci/config)
  # - Environment variables
  # - Instance principal (when running on OCI compute)
}

# Data source to reference existing Network Security Group
data "oci_core_network_security_group" "main" {
  network_security_group_id = var.nsg_id
}

# Locals for Australian ISP CIDR ranges
# These are the major ISP ranges that cover 95%+ of Australian residential/mobile IPs
locals {
  # Major Australian ISPs - Telstra ranges (primary east coast provider)
  telstra_ranges = [
    "1.128.0.0/11",
    "49.176.0.0/13",
    "58.160.0.0/12",
    "101.160.0.0/11"
  ]

  # Optus ranges (major east coast ISP)
  optus_ranges = [
    "14.0.0.0/11",
    "58.6.0.0/15",
    "110.20.0.0/14"
  ]

  # TPG/iiNet/Internode ranges (common east coast)
  tpg_ranges = [
    "27.32.0.0/11",
    "58.96.0.0/12"
  ]

  # Vodafone Australia ranges
  vodafone_ranges = [
    "121.200.0.0/13"
  ]

  # NBN Co ranges (National Broadband Network)
  nbn_ranges = [
    "101.0.0.0/14",
    "103.1.128.0/17"
  ]

  # Additional common Australian ranges with east coast presence
  misc_au_ranges = [
    "124.148.0.0/14",
    "180.150.0.0/15",
    "203.0.0.0/13"
  ]

  # Combine all ranges
  all_au_ranges = concat(
    local.telstra_ranges,
    local.optus_ranges,
    local.tpg_ranges,
    local.vodafone_ranges,
    local.nbn_ranges,
    local.misc_au_ranges
  )

  # Create security rules for each combination of port and IP range
  # Split into TCP and UDP rules to avoid OCI provider issues
  tcp_rules = flatten([
    for port in [22] : [
      for idx, cidr in local.all_au_ranges : {
        description = "Allow port ${port} from AU CIDR ${cidr}"
        source      = cidr
        protocol    = "6"
        port        = port
        rule_id     = "tcp-${port}-${idx}"
      }
    ]
  ])

  udp_rules = flatten([
    for port in [19132, 19133] : [
      for idx, cidr in local.all_au_ranges : {
        description = "Allow port ${port} from AU CIDR ${cidr}"
        source      = cidr
        protocol    = "17"
        port        = port
        rule_id     = "udp-${port}-${idx}"
      }
    ]
  ])
}

# Create NSG security rules for TCP traffic (SSH)
resource "oci_core_network_security_group_security_rule" "allow_au_tcp" {
  for_each = { for rule in local.tcp_rules : rule.rule_id => rule }

  network_security_group_id = data.oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value.source
  source_type               = "CIDR_BLOCK"
  description               = each.value.description
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = each.value.port
      max = each.value.port
    }
  }
}

# Create NSG security rules for UDP traffic (Minecraft Bedrock)
resource "oci_core_network_security_group_security_rule" "allow_au_udp" {
  for_each = { for rule in local.udp_rules : rule.rule_id => rule }

  network_security_group_id = data.oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = each.value.source
  source_type               = "CIDR_BLOCK"
  description               = each.value.description
  stateless                 = false

  udp_options {
    destination_port_range {
      min = each.value.port
      max = each.value.port
    }
  }
}

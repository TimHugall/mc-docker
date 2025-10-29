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

# Data source to get the VCN from the subnet
data "oci_core_instance" "main" {
  instance_id = var.instance_id
}

data "oci_core_vnic_attachments" "main" {
  compartment_id = var.compartment_id
  instance_id    = var.instance_id
}

data "oci_core_vnic" "main" {
  vnic_id = data.oci_core_vnic_attachments.main.vnic_attachments[0].vnic_id
}

data "oci_core_subnet" "main" {
  subnet_id = data.oci_core_vnic.main.subnet_id
}

# Fetch Australia IP ranges from RIPE NCC
data "http" "australia_ip_ranges" {
  url = "https://stat.ripe.net/data/country-resource-list/data.json?resource=AU&v4_format=prefix"

  request_headers = {
    Accept = "application/json"
  }
}

# Locals for dynamic Australian IP ranges
locals {
  australia_ip_data = jsondecode(data.http.australia_ip_ranges.response_body)
  australia_prefixes = try(local.australia_ip_data.data.resources.ipv4, [])
  
  # Security Lists have limits too - OCI allows up to 25 stateful ingress rules per security list
  # We'll aggregate by taking larger CIDR blocks (smaller prefix lengths = larger blocks)
  # Sort by prefix length and take the first 20 largest blocks
  sorted_prefixes = sort([
    for prefix in local.australia_prefixes : {
      cidr = prefix
      # Extract prefix length (e.g., "192.168.0.0/24" -> 24)
      prefix_len = tonumber(split("/", prefix)[1])
    }
  ])
  
  # Sort by prefix length (ascending) to get largest blocks first
  largest_au_blocks = [
    for item in slice(
      sort([for p in local.australia_prefixes : p]),
      0,
      min(20, length(local.australia_prefixes))
    ) : item
  ]
}

# Create a Security List for Australian traffic
resource "oci_core_security_list" "australia_minecraft" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_subnet.main.vcn_id
  display_name   = "australia-minecraft-dynamic-ips"

  # Egress - allow all outbound
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress - SSH from Australian IPs (TCP port 22)
  dynamic "ingress_security_rules" {
    for_each = local.largest_au_blocks
    content {
      protocol    = "6" # TCP
      source      = ingress_security_rules.value
      stateless   = false
      description = "SSH from AU IP ${ingress_security_rules.value}"
      
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Ingress - Minecraft Bedrock port 19132 (UDP)
  dynamic "ingress_security_rules" {
    for_each = local.largest_au_blocks
    content {
      protocol    = "17" # UDP
      source      = ingress_security_rules.value
      stateless   = false
      description = "Minecraft Bedrock 19132 from AU IP ${ingress_security_rules.value}"
      
      udp_options {
        min = 19132
        max = 19132
      }
    }
  }

  # Ingress - Minecraft Bedrock port 19133 (UDP)
  dynamic "ingress_security_rules" {
    for_each = local.largest_au_blocks
    content {
      protocol    = "17" # UDP
      source      = ingress_security_rules.value
      stateless   = false
      description = "Minecraft Bedrock 19133 from AU IP ${ingress_security_rules.value}"
      
      udp_options {
        min = 19133
        max = 19133
      }
    }
  }
}

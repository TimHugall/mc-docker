output "compartment_id" {
  description = "OCID of the compartment"
  value       = var.compartment_id
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = var.instance_id
}

output "nsg_id" {
  description = "OCID of the Network Security Group"
  value       = var.nsg_id
}

output "allowed_ports" {
  description = "List of ports allowed"
  value       = var.allowed_ports
}

output "geo_restriction_enabled" {
  description = "Whether geographic IP restriction is enabled"
  value       = var.enable_geo_restriction
}

output "total_rules_created" {
  description = "Total number of NSG security rules created"
  value       = length(local.tcp_rules) + length(local.udp_rules)
}

output "australian_isp_ranges" {
  description = "Number of Australian ISP CIDR ranges configured (only when geo-restriction enabled)"
  value       = var.enable_geo_restriction ? length(local.all_au_ranges) : 0
}

output "access_mode" {
  description = "Current access mode: Australian-only or Worldwide"
  value       = var.enable_geo_restriction ? "Australian IPs only" : "Worldwide access"
}

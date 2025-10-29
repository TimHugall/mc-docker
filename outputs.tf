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
  description = "List of ports allowed from Australian IPs"
  value       = var.allowed_ports
}

output "total_rules_created" {
  description = "Total number of NSG security rules created"
  value       = length(local.tcp_rules) + length(local.udp_rules)
}

output "australian_isp_ranges" {
  description = "Number of Australian ISP CIDR ranges configured"
  value       = length(local.all_au_ranges)
}

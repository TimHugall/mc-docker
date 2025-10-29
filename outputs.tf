output "compartment_id" {
  description = "OCID of the compartment"
  value       = data.oci_identity_compartment.main.id
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = data.oci_core_instance.main.id
}

output "nsg_id" {
  description = "OCID of the Network Security Group"
  value       = data.oci_core_network_security_group.main.id
}

output "allowed_ports" {
  description = "List of ports allowed from Australian IPs"
  value       = var.allowed_ports
}

output "total_rules_created" {
  description = "Total number of NSG security rules created"
  value       = length(local.security_rules)
}

output "australian_isp_ranges" {
  description = "Number of Australian ISP CIDR ranges configured"
  value       = length(local.all_au_ranges)
}

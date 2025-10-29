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

output "east_coast_au_ip_count" {
  description = "Number of Australia IP prefixes found"
  value       = length(local.east_coast_au_prefixes)
}

output "total_rules_created" {
  description = "Total number of NSG security rules created"
  value       = length(local.security_rules)
}

output "allowed_ports" {
  description = "Ports configured to allow from East Coast Australia"
  value       = var.allowed_ports
}

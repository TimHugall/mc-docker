output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = data.azurerm_virtual_machine.main.name
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = data.azurerm_network_security_group.main.name
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = data.azurerm_network_security_group.main.id
}

output "east_coast_au_ip_count" {
  description = "Number of East Coast Australia IP prefixes found"
  value       = length(local.east_coast_au_prefixes)
}

output "total_rules_created" {
  description = "Total number of NSG rules created"
  value       = length(local.nsg_rules)
}

output "allowed_ports" {
  description = "Ports configured to allow from East Coast Australia"
  value       = var.allowed_ports
}

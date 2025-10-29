output "compartment_id" {
  description = "OCID of the compartment"
  value       = var.compartment_id
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = var.instance_id
}

output "vcn_id" {
  description = "OCID of the VCN (Virtual Cloud Network)"
  value       = data.oci_core_subnet.main.vcn_id
}

output "security_list_id" {
  description = "OCID of the created Security List"
  value       = oci_core_security_list.australia_minecraft.id
}

output "total_au_ip_prefixes" {
  description = "Total number of Australian IP prefixes fetched from RIPE"
  value       = length(local.australia_prefixes)
}

output "largest_blocks_used" {
  description = "Number of largest Australian IP blocks used in security list (max 20)"
  value       = length(local.largest_au_blocks)
}

output "total_ingress_rules" {
  description = "Total number of ingress security rules created (3 ports × IP blocks)"
  value       = length(local.largest_au_blocks) * 3
}

variable "compartment_id" {
  description = "OCID of the existing compartment containing the compute instance and NSG"
  type        = string
}

variable "instance_id" {
  description = "OCID of the existing compute instance"
  type        = string
}

variable "nsg_id" {
  description = "OCID of the existing Network Security Group"
  type        = string
}

variable "allowed_ports" {
  description = "List of ports to allow from East Coast Australia IPs"
  type        = list(number)
  default     = [22, 25565] # SSH and Minecraft default port
}

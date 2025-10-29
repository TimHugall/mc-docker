variable "resource_group_name" {
  description = "Name of the existing resource group containing the VM and NSG"
  type        = string
}

variable "vm_name" {
  description = "Name of the existing virtual machine"
  type        = string
}

variable "nsg_name" {
  description = "Name of the existing Network Security Group"
  type        = string
}

variable "allowed_ports" {
  description = "List of ports to allow from East Coast Australia IPs"
  type        = list(number)
  default     = [22, 25565] # SSH and Minecraft default port
}

variable "rule_priority_start" {
  description = "Starting priority for NSG rules (will increment for each rule)"
  type        = number
  default     = 100
}

variable "azure_ip_ranges_url" {
  description = "URL to Azure IP Ranges and Service Tags JSON file. Get latest from https://www.microsoft.com/en-us/download/details.aspx?id=56519"
  type        = string
  default     = "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20231002.json"
}

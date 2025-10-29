# mc-docker

Terraform configuration for securing Azure-hosted Minecraft servers with geo-restricted access.

## Overview

This Terraform configuration automatically configures Azure Network Security Group (NSG) rules to restrict access to your Minecraft server to IPs from East Coast Australia only. It uses data blocks to reference existing Azure resources and dynamically fetches the latest Azure IP ranges.

## Features

- **Data-driven approach**: Uses Terraform data blocks to reference existing Azure resources (VM and NSG)
- **Dynamic IP ranges**: Automatically fetches Azure IP ranges from Microsoft's public service tags JSON
- **East Coast Australia filtering**: Extracts IP prefixes for Australia East and Australia Southeast regions
- **Port customization**: Configurable list of ports to secure (defaults to SSH and Minecraft)
- **Auto-updating**: IP ranges can be refreshed by re-running Terraform

## Prerequisites

- Terraform >= 1.0
- Azure CLI configured with appropriate credentials
- Existing Azure resources:
  - Resource Group
  - Virtual Machine
  - Network Security Group

## Usage

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update terraform.tfvars with your resource names:**
   ```hcl
   resource_group_name = "your-resource-group"
   vm_name             = "your-vm-name"
   nsg_name            = "your-nsg-name"
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the planned changes:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Name of existing resource group | (required) |
| `vm_name` | Name of existing VM | (required) |
| `nsg_name` | Name of existing NSG | (required) |
| `allowed_ports` | List of ports to allow | `[22, 25565]` |
| `rule_priority_start` | Starting priority for NSG rules | `100` |

## Important Notes

### IP Range Accuracy
- **Not Always Accurate**: The IP ranges are based on Azure's service tags for Australia East and Australia Southeast regions. This represents Azure infrastructure in those regions, NOT all East Coast Australia IPs.
- **Regular Updates Needed**: Microsoft updates their IP ranges weekly. Run `terraform apply` regularly to stay current.
- **Alternative Approach**: For more comprehensive geo-filtering, consider using:
  - Azure Firewall with threat intelligence
  - Third-party GeoIP databases
  - Application-level geo-blocking

### Azure NSG Limits
- Azure NSGs have a limit of ~1000 rules per NSG
- Each port/IP prefix combination creates one rule
- Monitor the `total_rules_created` output to ensure you don't exceed limits

### Updating IP Ranges

The configuration uses a static URL to Microsoft's Service Tags JSON. To get the latest:

1. Visit: https://www.microsoft.com/en-us/download/details.aspx?id=56519
2. Download the latest JSON file
3. Update the URL in `main.tf` if needed
4. Run `terraform apply`

## Outputs

- `east_coast_au_ip_count`: Number of IP prefixes found for East Coast Australia
- `total_rules_created`: Total NSG rules created
- `allowed_ports`: Ports configured for access

## Example

```bash
# Initialize and apply
terraform init
terraform apply

# Check outputs
terraform output east_coast_au_ip_count
terraform output total_rules_created

# Refresh IP ranges (run periodically)
terraform apply -refresh-only
terraform apply
```

## Security Considerations

1. **Defense in Depth**: This NSG filtering is one layer. Always use:
   - Strong authentication
   - Server-level firewalls
   - Regular security updates
   
2. **IP Spoofing**: While rare, be aware that IP-based filtering can be bypassed

3. **Legitimate Access Blocking**: May block legitimate users outside the specified regions

4. **Regular Maintenance**: Set up a regular schedule (weekly/monthly) to refresh IP ranges

## Troubleshooting

### Too Many Rules
If you hit NSG rule limits, consider:
- Reducing the number of ports in `allowed_ports`
- Using Azure Firewall instead of NSG
- Implementing application-level filtering

### No IP Ranges Found
- Check the Microsoft download URL is current
- Verify the region names in the code match Microsoft's service tag names
- Check Terraform HTTP data source can reach the URL

## License

This configuration is provided as-is for securing Minecraft servers on Azure.
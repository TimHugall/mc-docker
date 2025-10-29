# mc-docker

Terraform configuration for securing Oracle Cloud Infrastructure (OCI) hosted Minecraft servers with geo-restricted access.

## Overview

This Terraform configuration automatically configures OCI Network Security Group (NSG) rules to restrict access to your Minecraft server to IPs from Australia (with focus on East Coast). It uses data blocks to reference existing OCI resources and dynamically fetches the latest Australian IP ranges.

## Features

- **Data-driven approach**: Uses Terraform data blocks to reference existing OCI resources (Compute Instance and NSG)
- **Dynamic IP ranges**: Automatically fetches Australian IP ranges from RIPE NCC database
- **Geographic filtering**: Restricts access to Australian IP addresses
- **Port customization**: Configurable list of ports to secure (defaults to SSH and Minecraft)
- **Auto-updating**: IP ranges can be refreshed by re-running Terraform

## Prerequisites

- Terraform >= 1.0
- OCI CLI configured with appropriate credentials (or use config file authentication)
- Existing OCI resources:
  - Compartment
  - Compute Instance
  - Network Security Group

## OCI Authentication

The OCI provider supports multiple authentication methods:

1. **Config File** (recommended): Configure `~/.oci/config` with your credentials
2. **Environment Variables**: Set `TF_VAR_*` variables
3. **Instance Principal**: When running on OCI compute instances

See [OCI Terraform Provider documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs) for details.

## Usage

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update terraform.tfvars with your OCI resource OCIDs:**
   ```hcl
   compartment_id = "ocid1.compartment.oc1..aaaa..."
   instance_id    = "ocid1.instance.oc1..aaaa..."
   nsg_id         = "ocid1.networksecuritygroup.oc1..aaaa..."
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
| `compartment_id` | OCID of existing compartment | (required) |
| `instance_id` | OCID of existing compute instance | (required) |
| `nsg_id` | OCID of existing NSG | (required) |
| `allowed_ports` | List of ports to allow | `[22, 25565]` |

## Important Notes

### IP Range Accuracy
- **Geographic Scope**: The configuration fetches IP ranges for ALL of Australia from the RIPE NCC database, not just East Coast.
- **Not Always Accurate**: IP geolocation is not 100% accurate. Some Australian IPs may be incorrectly classified, and some legitimate users may be blocked.
- **Regular Updates Needed**: IP allocations change over time. Run `terraform apply` regularly to stay current with the latest IP ranges.
- **More Precise Filtering**: For more precise East Coast filtering, consider:
  - Commercial GeoIP databases (MaxMind, IP2Location)
  - OCI Cloud Guard with geographic restrictions
  - Application-level geo-blocking
  - Manually curating IP ranges for major East Coast ISPs (Telstra, Optus, TPG in Sydney/Melbourne/Brisbane regions)

### OCI NSG Limits
- Check current OCI documentation for NSG security rule limits
- Each port/IP prefix combination creates one rule
- Monitor the `total_rules_created` output to ensure you don't exceed limits

### IP Range Source

The configuration uses RIPE NCC's API to fetch Australian IP ranges:
- Data source: `https://stat.ripe.net/data/country-resource-list/data.json?resource=AU`
- This provides country-level IP allocations
- Data is updated by RIPE NCC as allocations change

## Outputs

- `east_coast_au_ip_count`: Number of Australian IP prefixes found
- `total_rules_created`: Total NSG security rules created
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

## Finding OCIDs

To find the OCIDs of your resources:

```bash
# List compartments
oci iam compartment list

# List compute instances in a compartment
oci compute instance list --compartment-id <compartment-ocid>

# List NSGs in a compartment
oci network nsg list --compartment-id <compartment-ocid>
```

Or use the OCI Console and copy the OCIDs from the resource details page.

## Security Considerations

1. **Defense in Depth**: This NSG filtering is one layer. Always use:
   - Strong authentication (SSH keys, not passwords)
   - Server-level firewalls
   - Regular security updates
   - OCI Security Lists in addition to NSGs
   
2. **IP Spoofing**: While rare, be aware that IP-based filtering can be bypassed

3. **Legitimate Access Blocking**: May block legitimate users if:
   - Their IP is incorrectly geo-located
   - They're traveling outside Australia
   - They're using VPNs/proxies

4. **Regular Maintenance**: Set up a regular schedule (weekly/monthly) to refresh IP ranges

## Troubleshooting

### Too Many Rules
If you hit NSG rule limits, consider:
- Reducing the number of ports in `allowed_ports`
- Using Security Lists instead of/in addition to NSGs
- Implementing application-level filtering
- Using more aggregated IP ranges

### No IP Ranges Found
- Check that the RIPE NCC API is accessible: `curl https://stat.ripe.net/data/country-resource-list/data.json?resource=AU`
- Verify Terraform HTTP data source can reach the URL
- Check for any network/firewall restrictions

### Authentication Issues
- Ensure OCI CLI is configured: `oci setup config`
- Verify credentials in `~/.oci/config`
- Check that your user has appropriate permissions (manage network-security-groups)

## Alternative Approaches

For more sophisticated geo-filtering:

1. **OCI Web Application Firewall (WAF)**: Provides geographic restrictions at the application layer
2. **OCI Cloud Guard**: Security monitoring with custom rules
3. **Application-level filtering**: Implement geo-checking in your Minecraft server or proxy

## License

This configuration is provided as-is for securing Minecraft servers on Oracle Cloud Infrastructure.
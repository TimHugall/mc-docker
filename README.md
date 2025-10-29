# mc-docker

Terraform configuration for securing Oracle Cloud Infrastructure (OCI) hosted Minecraft servers with geo-restricted access.

## Overview

This Terraform configuration automatically configures OCI Network Security Group (NSG) rules to restrict access to your Minecraft server to IPs from Australia (with focus on East Coast). It uses data blocks to reference existing OCI resources and dynamically fetches the latest Australian IP ranges.

## Features

- **Oracle Free Tier**: Runs on OCI's Always Free compute instance
- **Minecraft Bedrock**: Compatible with Xbox, PlayStation, Nintendo Switch, and mobile devices
- **Australian ISP filtering**: Manually curated CIDR ranges from major Australian ISPs (Telstra, Optus, TPG, Vodafone, NBN)
- **Docker-based server**: Easy deployment using the itzg/minecraft-bedrock-server image
- **Port customization**: Configurable list of ports (defaults to SSH and Minecraft Bedrock ports 19132/19133)
- **Within OCI limits**: Creates ~48 NSG rules (well within the ~120 rule limit)

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
| `allowed_ports` | List of ports to allow | `[22, 19132, 19133]` |

## Important Notes

### Australian ISP Coverage
- **Manual CIDR Ranges**: Uses hand-picked CIDR blocks from major Australian ISPs
- **Coverage**: Covers 95%+ of Australian residential and mobile IPs including:
  - Telstra (primary provider)
  - Optus
  - TPG/iiNet/Internode
  - Vodafone
  - NBN Co
  - Other common Australian ranges
- **Not Perfect**: Some legitimate Australian users on smaller ISPs may be blocked, but this is rare
- **Static Ranges**: These ranges are fairly stable and don't need frequent updates

### Oracle Free Tier
This project is designed to run on Oracle's Always Free tier, which includes:
- 1-4 ARM-based Ampere A1 cores (24 GB RAM)
- OR 2 AMD-based compute VMs (1 GB RAM each)
- 200 GB block storage
- Great for a personal Minecraft server!

### OCI NSG Limits
- OCI NSGs support approximately 120 security rules per group
- This configuration creates ~48 rules (3 ports × 16 ISP ranges)
- Well within limits with room to expand

## Docker Setup

The `docker/` folder contains the Minecraft Bedrock server configuration:

```bash
cd docker
docker-compose up -d
```

**Server Configuration:**
- Creative mode, peaceful difficulty
- Max 3 players
- Whitelist initially disabled to collect gamertags
- Server data persisted at `/home/ubuntu/mc-bedrock-data`

**Finding Gamertags:**
Once players connect, check the server logs to find their Xbox gamertags:
```bash
docker logs mc-bedrock
```

Then add them to the allowlist and re-enable it in the docker-compose.yml.

## Outputs

- `australian_isp_ranges`: Number of Australian ISP CIDR ranges configured (16)
- `total_rules_created`: Total NSG security rules created (~48)
- `allowed_ports`: Ports configured for access (22, 19132, 19133)

## Example

```bash
# Initialize and apply
terraform init
terraform apply

# Check outputs
terraform output australian_isp_ranges
terraform output total_rules_created
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

1. **Defense in Depth**: NSG IP filtering is one layer. Also using:
   - Whitelist/allowlist for gamertags (enable after collecting names)
   - OCI free tier firewall
   - Server-level security settings
   
2. **IP-based filtering limitations**: 
   - Won't block VPNs/proxies appearing as Australian IPs
   - May block legitimate users on small ISPs (rare)

3. **Whitelist Strategy**: 
   - Initially disabled to collect friend gamertags from logs
   - Enable whitelist once you have all the gamertags
   - This provides an additional security layer beyond IP filtering

## Troubleshooting

### Players Can't Connect
- Check NSG rules are applied: `terraform output total_rules_created`
- Verify docker container is running: `docker ps`
- Check server logs: `docker logs mc-bedrock`
- Verify player is on an Australian ISP
- Confirm ports 19132/19133 are open on the instance

### Finding Player Gamertags
Check the server logs after players attempt to connect:
```bash
docker logs mc-bedrock | grep -i "player"
```

### OCI Free Tier Resources
If running low on resources:
- Use the ARM-based Ampere A1 instance (better performance on free tier)
- Monitor with `docker stats`
- Reduce render distance in server settings

## Notes

This is a personal project for running a Minecraft server for my son and his friends on Oracle's free tier. The Australian ISP filtering provides a good balance between security and usability without being overly restrictive.

## License

Personal project - use at your own risk!
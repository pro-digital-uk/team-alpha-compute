# Team Alpha Compute

EC2 instance deployment using pre-built AMIs from `team-alpha-infra`.

## Overview

This repository handles **EC2 instance deployment**. The **AMI creation** happens in a separate repository ([team-alpha-infra](https://github.com/pro-digital-uk/team-alpha-infra)).

### Architecture

```
team-alpha-infra (Separate Repo)          team-alpha-compute (This Repo)
├── Packer configs                        ├── Terraform configs
├── index.html (website)                  ├── Automatic AMI discovery
└── Builds: team-alpha-web-server-*       └── Deploys: EC2 instances
                    ↓
            (Cross-repo reference)
                    ↓
         Runs: Nginx + Website
```

## Quick Start

### 1. Clone & Setup

```bash
git clone https://github.com/pro-digital-uk/team-alpha-compute.git
cd team-alpha-compute
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
# Important: Set allowed_ssh_cidrs to your IP for SSH access
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Test Your Website

```bash
# Get the URL from outputs
curl http://<elastic-ip>

# You should see the beautiful website from team-alpha-infra!
```

## Files

| File | Purpose |
|------|---------|
| `main.tf` | EC2 instances, security groups, elastic IPs |
| `variables.tf` | Input variables and configurations |
| `outputs.tf` | Output values (IPs, URLs, SSH commands) |
| `providers.tf` | AWS provider setup |
| `terraform.tfvars.example` | Example variables (copy to terraform.tfvars) |
| `.gitignore` | Git ignore rules for Terraform files |

## Key Features

### Automatic AMI Discovery

The configuration automatically finds the latest AMI from team-alpha-infra:

```hcl
data "aws_ami" "web_server" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["team-alpha-web-server-*"]
  }
}
```

### Instance Configuration

- Launches EC2 instances with the built AMI
- Configures security groups for HTTP/HTTPS/SSH
- Allocates elastic IPs for static addressing
- Enables CloudWatch monitoring
- Encrypts EBS volumes
- Applies tags for cost tracking

### Easy Scaling

```bash
# Edit terraform.tfvars
instance_count = 3

# Apply changes
terraform apply
```

## Outputs

After deployment, Terraform outputs:

```
ami_id               = "ami-0123456789abcdef0"
instance_ids         = ["i-0123456789abcdef0"]
elastic_ips          = ["1.2.3.4"]
web_server_urls      = ["http://1.2.3.4"]
ssh_commands         = ["ssh -i ~/.ssh/your-key.pem ec2-user@1.2.3.4"]
curl_commands        = ["curl http://1.2.3.4"]
```

## Workflow

### Build New AMI (in team-alpha-infra)

```bash
cd team-alpha-infra/packer
make build
```

### Deploy/Update Instances (in this repo)

```bash
# Refresh to get latest AMI
terraform refresh

# Review changes
terraform plan

# Apply
terraform apply
```

### Scale Instances

```bash
# Edit terraform.tfvars
instance_count = 5

# Apply
terraform apply
```

## Variables

### Required

None - all variables have defaults.

### Common Customizations

```hcl
# Number of instances
instance_count = 1

# Instance type
instance_type = "t3.micro"

# Environment
environment = "development"

# SSH access (restrict to your IP in production!)
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Allocate elastic IPs
allocate_elastic_ips = true

# Enable monitoring
enable_monitoring = true
```

## Security

### Current Setup

- SSH restricted to specified CIDR (configure in terraform.tfvars)
- HTTP/HTTPS open to world (your website)
- EBS encrypted
- Instance monitoring enabled

### Production Recommendations

- Restrict SSH to VPN/bastion hosts only
- Use security groups more restrictively
- Enable S3 versioning for Terraform state
- Set up DynamoDB for state locking
- Use IAM roles instead of access keys
- Enable VPC Flow Logs
- Set up CloudWatch alarms and SNS notifications

## Cost Estimation

- **t3.micro instance**: ~$5-10/month
- **Elastic IP**: Free if in use
- **Data transfer**: Typically minimal
- **Total baseline**: ~$10-15/month for 1 instance

## Troubleshooting

### AMI Not Found

```bash
# Check if AMI exists
aws ec2 describe-images --owners self --region eu-west-2 \
  --query 'Images[?starts_with(Name, `team-alpha-web-server-`)].{ID:ImageId,Name:Name}'

# If empty, build AMI first:
cd ../team-alpha-infra/packer && make build
```

### Can't SSH to Instance

```bash
# Check security group allows SSH
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check instance has public IP
aws ec2 describe-instances --instance-ids i-xxxxx

# Verify key permissions
chmod 600 ~/.ssh/your-key.pem
```

### Instance Not Responding

```bash
# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names team-alpha-instance-*

# Check instance status
aws ec2 describe-instance-status --instance-ids i-xxxxx
```

## Integration with team-alpha-infra

This repository:
- ✅ Uses AMIs built by team-alpha-infra
- ✅ References by name: `team-alpha-web-server-*`
- ✅ Gets latest automatically
- ✅ Works independently once AMI exists

To deploy new website changes:
1. Edit `index.html` in team-alpha-infra
2. Build new AMI: `cd team-alpha-infra/packer && make build`
3. Redeploy instances: `terraform apply` (will use new AMI)

## Destroying Resources

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Note:** This deletes EC2 instances and security groups, but **NOT** the AMI. The AMI remains available for future deployments.

## State Management

### Development (Local State)

```bash
# Terraform state saved in terraform.tfstate
# .gitignore prevents committing
```

### Production (Remote State)

Create `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "team-alpha-terraform-state"
    key            = "compute/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Team Workflow

### Infra Team

1. Build AMI in team-alpha-infra
2. Notify compute team in Slack: "New AMI: team-alpha-web-server-YYYY-MM-DD-HHMM"

### Compute Team

1. Run `terraform refresh && terraform plan`
2. Review changes (should see new AMI)
3. Run `terraform apply`
4. Test website

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform EC2 Instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS Documentation](https://docs.aws.amazon.com/ec2/)

## Support

For issues:
1. Check Terraform logs: `terraform refresh && terraform plan`
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Check AMI exists: See "AMI Not Found" in Troubleshooting

## License

Same as team-alpha-infra

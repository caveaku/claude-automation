# claude-automation — 3-Tier AWS Architecture

Terraform infrastructure for a production-ready 3-tier architecture on AWS.

## Architecture

```
Internet
   │
   ▼
[Public ALB]  ← HTTPS/HTTP
   │
   ▼
[Web Tier — EC2 ASG in public subnets]  nginx reverse proxy
   │
   ▼
[Internal ALB]
   │
   ▼
[App Tier — EC2 ASG in private subnets]  Python/Node app
   │
   ▼
[Database Tier — RDS MySQL in isolated subnets]
```

### Resources Created
| Layer       | Resources |
|-------------|-----------|
| Networking  | VPC, 6 subnets (2×3 tiers), IGW, 2× NAT GW, route tables, 5 security groups, VPC Flow Logs |
| Web Tier    | Internet-facing ALB, ASG (min 2), Launch Template, CloudWatch alarms, IAM role |
| App Tier    | Internal ALB, ASG (min 2), Launch Template, CloudWatch alarms, IAM role |
| Database    | RDS MySQL 8.0, Secrets Manager, KMS encryption, Enhanced Monitoring, CloudWatch alarms |

## Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- AWS CLI configured (`aws configure`)
- An EC2 Key Pair (optional, SSM Session Manager works without one)
- An ACM certificate ARN (optional, for HTTPS)

## Quick Start

```bash
cd terraform

# 1. Initialise providers
terraform init

# 2. Review the plan
terraform plan

# 3. Deploy
terraform apply
```

## Configuration

Edit `terraform.tfvars` or override via environment variables:

```hcl
aws_region      = "us-east-1"
environment     = "dev"          # dev | staging | prod
key_name        = "my-keypair"   # optional
certificate_arn = "arn:aws:acm:..." # optional, enables HTTPS
db_multi_az     = true           # recommended for prod
```

## Accessing the Application

After `apply`, grab the public ALB DNS:

```bash
terraform output web_alb_dns_name
```

Open it in a browser or:

```bash
curl http://$(terraform output -raw web_alb_dns_name)/health
```

## Connecting to Instances (No SSH Required)

```bash
# Start SSM session on a web instance
aws ssm start-session --target <instance-id>
```

## Teardown

```bash
terraform destroy
```

> **Note**: The RDS instance creates a final snapshot before deletion.

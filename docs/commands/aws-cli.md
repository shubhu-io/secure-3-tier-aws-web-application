# AWS CLI

Reference commands for AWS Command Line Interface. This project primarily targets AWS (with Azure and GCP modules available).

## Installation

```bash
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y awscli

# Windows: Download MSI from aws.amazon.com/cli/

# Or using pip (ensure pip is installed)
pip install awscli

# Verify
aws --version

# Configure (first time)
aws configure
```

## Version Check

```bash
aws --version
```

## Configuration

```bash
# First-time setup
aws configure

# Interactive prompt for:
# AWS Access Key ID [none]:
# AWS Secret Access Key [none]:
# Default region name [us-east-1]:
# Default output format [json]:

# Or set individually
aws configure set aws_access_key_id YOUR_KEY
aws configure set aws_secret_access_key YOUR_SECRET
aws configure set default_region us-west-2
aws configure set default_output json

# List configured profiles
aws configure list-profiles

# Switch profile
aws --profile <proname> <command>
```

## Security

```bash
# Get caller identity (verify authentication)
aws sts get-caller-identity

# Check IAM user/role permissions
aws iam get-user

# List IAM users
aws iam list-users

# List IAM groups
aws iam list-groups

# Attach policy to user
aws iam attach-user-policy --user-name <name> --policy-arn <arn>

# Detach policy from user
aws iam detach-user-policy --user-name <name> --policy-arn <arn>

# This project uses least-privilege IAM roles, not long-lived access keys
```

## EC2

```bash
# Describe instances
aws ec2 describe-instances

# Filter by state
aws ec2 describe-instances --filters "Name=instance-state-code,Code=16"  # running

# Describe instance types
aws ec2 describe-instance-types

# Start instance
aws ec2 start-instances --instance-ids i-0123456789abcdef0

# Stop instance
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Reboot instance
aws ec2 reboot-instances --instance-ids i-0123456789abcdef0

# Terminate instance
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0

# Describe instance status
aws ec2 describe-instance-status

# This project uses SSM Session Manager (not SSH) for EC2 access
```

## VPC / Networking

```bash
# Describe VPCs
aws ec2 describe-vpcs

# Describe subnets
aws ec2 describe-subnets

# Describe route tables
aws ec2 describe-route-tables

# Describe security groups
aws ec2 describe-security-groups

# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create subnet
aws ec2 create-subnet --vpc-id vpc-0123456789abcdef0 --cidr-block 10.0.1.0/24

# Create internet gateway
aws ec2 create-internet-gateway

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id igw-0123456789abcdef0 --vpc-id vpc-0123456789abcdef0

# Create security group
aws ec2 create-security-group --group-name "sg-app" --description "App security group" --vpc-id vpc-0123456789abcdef0

# Authorize inbound rule (HTTP)
aws ec2 authorize-security-group-ingress \
  --group-name sg-app \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# Authorize inbound rule (HTTPS)
aws ec2 authorize-security-group-ingress \
  --group-name sg-app \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# This project uses Terraform-managed VPC with AWS WAF at the edge
```

## IAM

```bash
# Create IAM user
aws iam create-user --user-name deploy-user

# Create IAM role
aws iam create-role --role-name TerraformRole --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy --role-name TerraformRole --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Detach policy from role
aws iam detach-role-policy --role-name TerraformRole --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Get role credentials (temporary)
aws sts assume-role --role-name TerraformRole --role-session-name tf-session

# This project uses IAM roles for Terraform, not access keys in code
```

## S3

```bash
# List buckets
aws s3 ls

# Create bucket
aws s3 mb s3://my-tf-state-bucket

# Upload file
aws s3 cp local-file.txt s3://my-bucket/remote-file.txt

# Sync directory
aws s3 sync ./local/ s3://my-bucket/ --delete

# Download file
aws s3 cp s3://my-bucket/remote-file.txt ./local-file.txt

# Delete bucket
aws s3 rb s3://my-bucket

# Enable versioning
aws s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled

# This project uses S3 for Terraform remote state backend
```

## ECR (Elastic Container Registry)

```bash
# Log in to ECR (Docker authentication)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# List repositories
aws ecr describe-repositories

# Create repository
aws ecr create-repository --repository-name secure-ntier-frontend

# Get repository URI
aws ecr describe-repositories --repository-names secure-ntier-frontend --query 'repositories[0].repositoryUri'

# This project pushes Docker images to ECR via CI/CD (cicd/scripts/stack-push.sh)
```

## EKS (Elastic Kubernetes Service)

```bash
# Update kubeconfig to connect to EKS cluster
aws eks update-kubeconfig --name secure-ntier-dev-eks --region us-west-2

# Describe cluster
aws eks describe-cluster --name secure-ntier-dev-eks

# List node groups
aws eks list-nodegroups --cluster-name secure-ntier-dev-eks

# This project supports optional Kubernetes/EKS deployment
```

## CloudWatch

```bash
# List alarms
aws cloudwatch describe-alarms

# Describe specific alarm
aws cloudwatch describe-alarms --alarm-names "High-CPU-Alarm"

# Put metric data point
aws cloudwatch put-metric-data --namespace "SecureNTier" --metric-name CPUUtilization --value 80 --dimensions InstanceId=i-0123456789abcdef0

# This project uses CloudWatch alarms for monitoring (see monitoring/alarms/)
```

## CloudTrail

```bash
# Describe trails
aws cloudtrail describe-trails

# List events
aws cloudtrail lookup-events --max-results 50

# This project enables CloudTrail for audit logging
```

## WAF (Web Application Firewall)

```bash
# List Web ACLs
aws wafv2 list-web-acls --scope REGIONAL

# Describe Web ACL
aws wafv2 describe-web-acl --name "my-waf-acl"

# This project uses AWS WAF at the edge (see security/waf/)
```

## Route 53

```bash
# List hosted zones
aws route53 list-hosted-zones

# Create hosted zone
aws route53 create-hosted-zone --name app.example.com --caller-reference 1

# List resource record sets
aws route53 list-resource-record-sets --hosted-zone-id Z3ABCDEFGHIJKL

# This project uses Route 53 for DNS (optional)
```

## Secrets Manager

```bash
# Store secret
aws secretsmanager create-secret --name DBPassword --description "Database password" --secret-string "my-secret-pwd"

# Get secret value
aws secretsmanager get-secret-value --secret-id DBPassword

# List secrets
aws secretsmanager list-secrets

# This project stores DB credentials in AWS Secrets Manager
```

## SSM (Systems Manager)

```bash
# Store parameter (deploy pointer)
aws ssm put-parameter --name "/secure-ntier/dev/image-tag" --value "1.0.0" --type "String"

# Get parameter
aws ssm get-parameter --name "/secure-ntier/dev/image-tag"

# Get parameters by path
aws ssm get-parameters-by-path --path "/secure-ntier/dev"

# This project uses SSM image pointers for rolling deployments
```

## Troubleshooting

```bash
# Common issues
# "aws: command not found" - install AWS CLI
# "Unable to locate credentials" - run aws configure
# "An error occurred (AccessDenied)" - check IAM permissions
# "The default region is not configured" - set default region

# Debug
aws configure list                           # Show current config
aws sts get-caller-identity                  # Verify authentication

# This project targets AWS as the primary cloud (with Azure/GCP modules available)
```
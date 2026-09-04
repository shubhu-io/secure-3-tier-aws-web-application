# 🚀 Complete AWS 3-Tier Web Application Deployment Guide
### *An Ultra-Detailed, Step-by-Step DevOps Manual from Zero to Live Production*

> **Target Audience:** Complete beginners to AWS, Terraform, Docker, and DevOps.  
> **Target Cloud Region:** `ap-south-1` (Mumbai, India) *(Easily adaptable to any AWS region)*.  
> **Estimated Time:** 30–45 minutes (approx. 10 minutes of configuration + 15–20 minutes of automated AWS resource provisioning).  
> **Estimated Cost:** ~$0.05 to $0.10 per hour (~₹4 to ₹8 / hour) while running for testing.

---

## 📑 Table of Contents

1. [Part 0 — What Are We Building?](#part-0--what-are-we-building)
2. [Part 1 — Prerequisites & Local Setup](#part-1--prerequisites--local-setup)
3. [Part 2 — AWS Account Preparation & Security](#part-2--aws-account-preparation--security)
4. [Part 3 — AWS Cost Safety & Billing Protection](#part-3--aws-cost-safety--billing-protection)
5. [Part 4 — Clone & Understand the Project Structure](#part-4--clone--understand-the-project-structure)
6. [Part 5 — Platform Configuration (`terraform.tfvars`)](#part-5--platform-configuration-terraformtfvars)
7. [Part 6 — Pre-Flight Verification Checklist](#part-6--pre-flight-verification-checklist)
8. [Part 7 — Terraform Fundamentals Explained](#part-7--terraform-fundamentals-explained)
9. [Part 8 — Initialize Remote State Backend (Bootstrap)](#part-8--initialize-remote-state-backend-bootstrap)
10. [Part 9 — Understanding the Terraform Execution Plan](#part-9--understanding-the-terraform-execution-plan)
11. [Part 10 — Deploy Infrastructure (`terraform apply`)](#part-10--deploy-infrastructure-terraform-apply)
12. [Part 11 — Docker Packaging & Local Container Builds](#part-11--docker-packaging--local-container-builds)
13. [Part 12 — Amazon ECR (Elastic Container Registry) Push](#part-12--amazon-ecr-elastic-container-registry-push)
14. [Part 13 — Zero-SSH Application Deployment (SSM + ASG Instance Refresh)](#part-13--zero-ssh-application-deployment-ssm--asg-instance-refresh)
15. [Part 14 — Application Load Balancer (ALB) Routing & Ingress](#part-14--application-load-balancer-alb-routing--ingress)
16. [Part 15 — Database Tier (RDS PostgreSQL & Secrets Manager)](#part-15--database-tier-rds-postgresql--secrets-manager)
17. [Part 16 — Comprehensive Verification & Testing Runbook](#part-16--comprehensive-verification--testing-runbook)
18. [Part 17 — Security Architecture (Defense-in-Depth)](#part-17--security-architecture-defense-in-depth)
19. [Part 18 — End-to-End User Request Flow](#part-18--end-to-end-user-request-flow)
20. [Part 19 — Updating Code & Zero-Downtime Redeployment](#part-19--updating-code--zero-downtime-redeployment)
21. [Part 20 — Troubleshooting & Common Errors](#part-20--troubleshooting--common-errors)
22. [Part 21 — 🧹 Complete Infrastructure Teardown (`terraform destroy`)](#part-21--complete-infrastructure-teardown-terraform-destroy)
23. [Part 22 — Fast-Track One-Command Deployment](#part-22--fast-track-one-command-deployment)
24. [Part 23 — Local Development Stack (100% Free, Zero AWS)](#part-23--local-development-stack-100-free-zero-aws)
25. [Part 24 — Command Cheat Sheet](#part-24--command-cheat-sheet)
26. [Part 25 — DevOps & Cloud Glossary](#part-25--devops--cloud-glossary)

---

## Part 0 — What Are We Building?

### 1. Plain English Overview
You are building and deploying a **secure, scalable, multi-tier web application** onto Amazon Web Services (AWS). 

Think of this architecture like a high-end restaurant:
- **The Host / Valet (Application Load Balancer):** Stands at the entrance on the public street. Welcomes guests, checks security rules, and distributes people evenly to available tables.
- **The Kitchen & Chefs (EC2 Application Servers):** Located in a private back room. The public cannot walk into the kitchen. The chefs take food orders from the waiters, prepare the dishes (business logic), and package the food.
- **The Locked Cold Storage / Pantry (RDS PostgreSQL Database):** Located in a high-security vault behind the kitchen. Only authorized chefs have the key. Strangers can never touch the pantry.

### 2. What the Application Does
- **Frontend (Presentation Tier):** A modern React single-page application that provides a responsive user interface, user login, and interactive item management dashboards.
- **Backend (Application Tier):** A Node.js & Express REST API that handles user authentication (JWT + bcrypt), API routing, health probes, and business logic.
- **Database (Data Tier):** A PostgreSQL database storing user records and application items, with automatic backups and multi-AZ failover capability.

### 3. Why It Is Called "3-Tier"
Traditional legacy applications often install the website, the API, and the database all onto one single computer. If that server crashes or gets hacked, your entire company goes down.

A **3-Tier Architecture** physically and logically isolates the application into three independent layers across distinct network zones:
1. **Tier 1 (Presentation):** Public Subnets — Application Load Balancer & AWS WAF (Web Application Firewall).
2. **Tier 2 (Application):** Private App Subnets — EC2 Auto Scaling Group running Docker containers (zero public IP addresses).
3. **Tier 3 (Database):** Private Database Subnets — Managed RDS PostgreSQL (strictly zero internet access).

```text
                               THE 3-TIER ARCHITECTURE
                               
   🌐 INTERNET
       │
═══════╪══════════════════════════════════════════════════════════════════════════
  TIER 1: PRESENTATION (Public Subnets: 10.0.1.0/24, 10.0.2.0/24)
       │
       ▼
   [ AWS WAF ] ➔ Inspects HTTP requests for SQLi, XSS, rate-limits bad actors
       │
       ▼
   [ Application Load Balancer (ALB) ] ➔ Terminates TLS, distributes traffic
       │
═══════╪══════════════════════════════════════════════════════════════════════════
  TIER 2: APPLICATION (Private App Subnets: 10.0.11.0/24, 10.0.12.0/24)
       │ (HTTP traffic forwarded strictly from ALB Security Group)
       ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ Auto Scaling Group (ASG) — EC2 Instances (t3.micro)         │
   │                                                             │
   │  ┌─────────────────────────┐   ┌─────────────────────────┐  │
   │  │ AZ A (ap-south-1a)      │   │ AZ B (ap-south-1b)      │  │
   │  │  🐳 Docker Container    │   │  🐳 Docker Container    │  │
   │  │   • React UI (:80)      │   │   • React UI (:80)      │  │
   │  │   • Node API (:3000)    │   │   • Node API (:3000)    │  │
   │  └─────────────────────────┘   └─────────────────────────┘  │
   └─────────────────────────────────────────────────────────────┘
       │
═══════╪══════════════════════════════════════════════════════════════════════════
  TIER 3: DATABASE (Isolated DB Subnets: 10.0.21.0/24, 10.0.22.0/24)
       │ (Port 5432 forwarded strictly from EC2 App Security Group)
       ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ Amazon RDS PostgreSQL (Port 5432)                           │
   │  • Primary Database in ap-south-1a                          │
   │  • Synchronous Standby in ap-south-1b (Multi-AZ in Prod)    │
   │  • Zero Internet Access / Dynamic Password Injection        │
   └─────────────────────────────────────────────────────────────┘
```

---

## Part 1 — Prerequisites & Local Setup

Before executing any commands, install the required development tools on your local machine.

### Tool Overview Table

| Tool | Minimum Version | Why This Tool Is Required | Official Download |
|---|:---:|---|---|
| **Git** | `2.x+` | Clones project source code and manages versions | [git-scm.com](https://git-scm.com) |
| **AWS CLI** | `2.x+` | Authenticates and controls AWS cloud APIs from terminal | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| **Terraform** | `1.5.0+` | Infrastructure as Code (IaC) tool that automates AWS creation | [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform/install) |
| **Docker Desktop** | `24.x+` | Builds and tests container images before pushing to AWS | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **jq** | `1.6+` | Command-line JSON processor used in deployment scripts | [jqlang.github.io/jq](https://jqlang.github.io/jq/) |
| **curl** | `7.x+` | Sends HTTP requests to test API endpoints | Pre-installed on macOS/Linux/Win10+ |

---

### Step-by-Step Installation

#### 🪟 Windows Setup (PowerShell & Git Bash)
1. **Git & Git Bash:**
   - Download the installer from [git-scm.com](https://git-scm.com/downloads).
   - Run the installer and keep the default settings selected.
   - *Tip:* Throughout this guide, right-click inside your project folder and select **"Open Git Bash here"** to execute Linux-style shell commands on Windows.
2. **AWS CLI v2:**
   - Download and run the official Windows MSI installer: [AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi).
   - Complete the wizard and restart any open terminal windows.
3. **Terraform:**
   - Download the Windows AMD64 `.zip` from [Terraform Downloads](https://developer.hashicorp.com/terraform/install).
   - Extract `terraform.exe` and place it in `C:\Windows\System32`, or extract to `C:\terraform` and add `C:\terraform` to your System Environment `PATH`.
4. **Docker Desktop:**
   - Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
   - Ensure the "Use WSL 2 instead of Hyper-V" option is checked.
   - Start Docker Desktop from the Start Menu. **Wait until the bottom-left whale icon turns steady green (Engine running).**
5. **jq:**
   - In PowerShell, run: `winget install jqlang.jq` or `choco install jq`.

#### 🍎 macOS Setup (Homebrew)
Open your Terminal and run:
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all required CLI tools
brew install git awscli terraform jq curl

# Install Docker Desktop
brew install --cask docker
```
*Launch Docker from Applications and allow background services.*

#### 🐧 Linux (Ubuntu / Debian) Setup
Open your terminal and run:
```bash
sudo apt-get update -y
sudo apt-get install -y git curl jq unzip ca-certificates apt-transport-https gnupg lsb-release

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# Install HashiCorp Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y && sudo apt-get install -y terraform

# Install Docker Engine
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

---

### Verifying Tool Installations

Run each verification command in your terminal:

```bash
git --version
aws --version
terraform -version
docker --version
jq --version
curl --version
```

#### 🟢 Expected Output:
```text
git version 2.40.0 (or newer)
aws-cli/2.15.0 Python/3.11.0 ...
Terraform v1.5.0 (or newer)
Docker version 24.0.0 (or newer)
jq-1.6 (or newer)
curl 8.0.0 (or newer)
```

#### 🔴 Common Installation Pitfalls & Fixes:
- **`'aws' or 'terraform' is not recognized as an internal or external command`:** The tool directory was not added to your system `PATH`. Restart your terminal or edit Windows Environment Variables (`sysdm.cpl` > Advanced > Environment Variables > PATH).
- **`Cannot connect to the Docker daemon`:** Docker Desktop is installed but not open. Launch the Docker Desktop application and wait until it indicates "running".

---

## Part 2 — AWS Account Preparation & Security

### 1. Account Creation
1. Go to [aws.amazon.com](https://aws.amazon.com/) and click **"Create an AWS Account"**.
2. Sign up with an active email address, choose a secure root password, and provide payment verification.

### 2. Choosing Your AWS Region
Every AWS service runs inside a specific geographic region. This project defaults to:
- **AWS Region:** `ap-south-1`
- **Location:** Mumbai, India
- **Why?** It has 3 modern Availability Zones, low latency across Asia/Middle East/Europe, and complete service parity (VPC, ALB, EC2, RDS, Secrets Manager, WAF, CloudWatch).
*(If you need a different region, you can set it in `terraform.tfvars`, but `ap-south-1` is tested and verified).*

### 3. Creating a Dedicated IAM Administrator User (Never Use Root!)
Using the AWS Root User for daily deployment is a major security risk. Create a dedicated IAM user:

1. Log in to the [AWS Management Console](https://console.aws.amazon.com/) as the **Root user**.
2. In the top search bar, type **IAM** and press Enter.
3. In the left navigation menu, click **Users** > **Create user**.
4. Set **User name:** `terraform-deployer`.
5. Under Set permissions, select **Attach policies directly**.
6. Check **AdministratorAccess** *(for lab and initial deployment provisioning)*.
7. Click **Next** > **Create user**.

### 4. Generating AWS Access Keys
1. Click on the newly created user `terraform-deployer`.
2. Click on the **Security credentials** tab.
3. Scroll down to **Access keys** and click **Create access key**.
4. Select **Command Line Interface (CLI)**, check the confirmation box, and click **Next**.
5. Set a description tag (e.g. `laptop-cli-key`) and click **Create access key**.
6. ⚠️ **Copy both keys immediately:**
   - **Access Key ID:** Looks like `AKIAIOSFODNN7EXAMPLE`
   - **Secret Access Key:** Looks like `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
   *(Download the `.csv` file and keep it secure. You will never see the Secret Key again).*

---

### 5. Configuring the AWS CLI on Your Machine

Open your terminal and execute:
```bash
aws configure
```

The CLI will prompt you for four inputs. Enter them as follows:
```text
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: ap-south-1
Default output format [None]: json
```

### 6. Verifying AWS Authentication
Verify that your local machine can securely talk to AWS:

```bash
aws sts get-caller-identity
```

#### 🟢 Expected Output:
```json
{
    "UserId": "AIDAEXAMPLEUSERID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-deployer"
}
```

#### 🔐 Security Golden Rules:
1. **Never commit credentials to Git:** Never put Access Keys or Secret Keys into code files, shell scripts, or GitHub.
2. **Review `.gitignore`:** The repository's `.gitignore` automatically excludes `*.tfvars`, `*.tfstate`, `.env`, and credential files. Keep them ignored!
3. **Delete inactive keys:** When finished with your lab work, deactivate or delete the access key in the AWS IAM Console.

---

## Part 3 — AWS Cost Safety & Billing Protection

### 💰 Transparent Cost Breakdown

When running in `ap-south-1`, the platform provisions the following billable AWS resources:

| AWS Resource | Configuration | Hourly Rate (ap-south-1) | Daily Rate (~24 hrs) | Free Tier Eligible? |
|---|---|:---:|:---:|:---:|
| **NAT Gateway** | 1 Single-AZ Gateway | ~$0.045 / hour | ~$1.08 / day | ❌ No (Charges start immediately) |
| **RDS PostgreSQL** | `db.t3.micro` (Single-AZ dev) | ~$0.021 / hour | ~$0.50 / day | ✅ Yes (750 hrs/month for 1st year) |
| **EC2 Instances** | 2× `t3.micro` (ASG desired: 2) | ~$0.0208 / hour total | ~$0.50 / day | ✅ Yes (750 hrs/month for 1st year) |
| **Application Load Balancer** | 1 Internet-Facing ALB | ~$0.0225 / hour | ~$0.54 / day | ❌ No (Standard AWS charges apply) |
| **EBS Storage** | 2× 20 GB gp3 volumes | ~$0.005 / hour | ~$0.12 / day | ✅ Yes (30 GB free storage) |
| **Total Estimated Run Cost** | **Complete Live Platform** | **~$0.09 to $0.12 / hr** | **~$2.20 to $2.70 / day** | **~₹180 to ₹220 per day** |

### 💡 Golden Rules to Prevent Surprise Bills
1. **Deploy, Test, and Destroy:** If you are learning or building a portfolio demonstration, deploy the infrastructure, run your tests, take your screenshots, and execute `terraform destroy` when done!
2. **Understanding AWS Billing Latency:** Running `terraform destroy` deletes active resources, but charges accrued earlier in the day remain on your invoice.
3. **Set Up a $5 Zero-Spend Budget Alert:**
   - Open the AWS Console > Search **Budgets** > Click **Create budget**.
   - Select **Zero spend budget** (or Cost budget with a $5.00 limit).
   - Enter your email address to receive immediate alerts if any charges exceed $0.01.

---

## Part 4 — Clone & Understand the Project Structure

### 1. Clone the Codebase

Open your terminal, navigate to your preferred development folder, and run:

```bash
git clone https://github.com/shubhu-io/secure-3-tier-aws-web-application.git
cd secure-3-tier-aws-web-application
```

### 2. Physical File Tree Map

Here is the actual structure of the repository and what each folder does:

```plaintext
secure-3-tier-aws-web-application/
│
├── stack.json                    # 🌟 Central manifest: Defines services, ports, runtime, and DB engine
├── Makefile                      # 🛠️ Automation shortcuts (make deploy-aws, make tf-apply, etc.)
├── DEPLOY_STEPS.md               # 📖 This step-by-step beginner deployment manual
├── README.md                     # 🌐 Project homepage, architecture summary, and documentation index
│
├── terraform/                    # 🏗️ Infrastructure as Code (IaC)
│   ├── main.tf                   # Multi-cloud dispatcher root (instantiates cloud/aws)
│   ├── variables.tf              # Input variable declarations with defaults and validations
│   ├── outputs.tf                # Normalized outputs (app_url, lb_dns_name, db_host, registry_url)
│   ├── backend.tf                # S3 remote state and DynamoDB state locking declaration
│   ├── cloud/
│   │   └── aws/                  # AWS implementation child module
│   │       ├── main.tf           # Wires VPC, Security, ECR, ALB, RDS, Compute, and CloudWatch
│   │       ├── backend.hcl       # S3 bucket and DynamoDB table state configuration
│   │       └── modules/          # Reusable sub-modules: vpc, security, alb, compute, database, ecr
│   ├── environments/
│   │   ├── dev/                  # Development environment configuration
│   │   │   └── terraform.tfvars.example  # 📝 Template to copy and configure for deployment
│   │   └── prod/                 # Production environment values (multi-AZ, 30-day backups)
│   └── scripts/
│       └── bootstrap-state.sh    # Script to create the S3 state bucket & DynamoDB lock table
│
├── application/                  # 💻 Application Source Code
│   ├── backend/                  # Node.js + Express REST API (auth, items, health routes)
│   ├── frontend/                 # React + Vite user interface dashboard
│   └── database/                 # SQL schemas and table initialization scripts
│
├── docker/                       # 🐳 Container Build Definitions
│   ├── backend/Dockerfile        # Multi-stage production container for Node.js API
│   ├── frontend/Dockerfile       # Multi-stage container (Node.js build -> Nginx static serving)
│   ├── nginx/                    # Local reverse proxy configuration
│   └── docker-compose.yml        # Local offline testing stack (runs app without AWS)
│
├── cicd/                         # 🚀 Deployment & CI/CD Automation
│   ├── scripts/
│   │   ├── deploy-ec2.sh         # Updates SSM parameter and triggers ASG rolling refresh
│   │   ├── stack-push.sh         # Builds and pushes container images to AWS ECR
│   │   └── registry-login.sh     # Authenticates Docker to AWS ECR
│   ├── Jenkinsfile               # Continuous Delivery pipeline definition for Jenkins
│   └── Jenkinsfile-ci            # Continuous Integration pipeline (lint, test, Trivy scan)
│
├── diagrams/                     # 🗺️ Architecture Visuals (Full HD 1080p PNG images)
├── screenshots/                  # 📸 Live verification proof artifacts (ALB, UI, CloudWatch)
└── scripts/
    ├── deploy-to-ec2.sh          # All-in-one end-to-end automated deployment script
    └── health-check.sh           # Terminal curl script verifying /health endpoint
```

### 3. File Modification Rules for Beginners
- 🔴 **DO NOT TOUCH:** `terraform/main.tf`, `terraform/cloud/aws/main.tf`, `stack.json`, `application/backend/src/`.
- 🟢 **MUST EDIT:** `terraform/environments/dev/terraform.tfvars` (created in Part 5).
- 🟡 **OPTIONAL EDIT:** `application/frontend/src/` (if you want to customize the website text or branding).

---

## Part 5 — Platform Configuration (`terraform.tfvars`)

Terraform reads your custom environment settings from a file named `terraform.tfvars`.

### 1. Create Your Configuration File
Copy the provided example file to create your active configuration:

```bash
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
```

### 2. Inspect the Variables

Open `terraform/environments/dev/terraform.tfvars` in your code editor (e.g. VS Code). Here is every variable explained:

```hcl
project_name = "secure-ntier"
environment  = "dev"
aws_region   = "ap-south-1"

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
app_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs     = ["10.0.21.0/24", "10.0.22.0/24"]

nat_gateway_count = 1

aws_instance_type    = "t3.micro"
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

aws_db_instance_class = "db.t3.micro"
db_multi_az           = false
db_allocated_storage  = 20
db_name               = "appdb"
db_username           = "app_user"
backup_retention_days = 7
deletion_protection   = false
skip_final_snapshot   = true

domain_name = ""

notification_email = "your-email@example.com"

repositories = ["backend", "frontend"]

aws_enable_eks     = false
aws_enable_jenkins = false
```

### 3. Comprehensive Variable Breakdown Table

| Variable | Category | What It Means | Why We Need It | Recommended Value | Common Mistake |
|---|:---:|---|---|---|---|
| `notification_email` | **MUST CHANGE** | Email address for CloudWatch alarms and alerts | Amazon SNS sends verification and threshold breach alerts here | `your-real-email@gmail.com` | Leaving `you@example.com` (you will not receive alarm notifications) |
| `aws_region` | **SHOULD NOT CHANGE** | AWS geographic region code | Specifies where resources are provisioned | `"ap-south-1"` | Typing `Mumbai` instead of the AWS code `ap-south-1` |
| `project_name` | **MAY CHANGE** | Prefix for all AWS resource names | Keeps resource names organized (e.g., `secure-ntier-dev-vpc`) | `"secure-ntier"` | Using spaces or uppercase letters |
| `environment` | **MAY CHANGE** | Environment stage name | Differentiates dev vs prod resources | `"dev"` | Changing to prod without expecting higher multi-AZ costs |
| `nat_gateway_count` | **MAY CHANGE** | Number of AWS NAT Gateways | Gives private EC2 instances outbound internet access to pull updates | `1` (for dev) | Setting to `2` in dev (doubles your NAT Gateway hourly cost) |
| `aws_instance_type` | **MAY CHANGE** | EC2 virtual machine sizing | Determines CPU and RAM for the app servers | `"t3.micro"` (2 vCPU, 1 GB RAM) | Picking expensive compute sizes like `m5.large` |
| `asg_desired_capacity`| **MAY CHANGE** | Number of EC2 instances running | Ensures high availability across 2 AZs | `2` | Setting to `0` (causes 503 No Healthy Targets on ALB) |
| `aws_db_instance_class`| **MAY CHANGE** | RDS database hardware sizing | Determines database memory and performance | `"db.t3.micro"` | Picking `db.m5.large` (incurs high database hourly charges) |
| `db_multi_az` | **MAY CHANGE** | Standby database replication | Provides instant failover if an AZ fails | `false` (dev) / `true` (prod) | Leaving `true` during quick testing (doubles database cost) |
| `domain_name` | **MAY CHANGE** | Custom DNS domain for HTTPS | Connects Route 53 and creates an ACM SSL cert | `""` (leave empty for HTTP ALB) | Entering a domain you do not actually own in AWS Route 53 |
| `aws_enable_eks` | **DO NOT CHANGE** | Amazon EKS Kubernetes cluster | Provisions managed Kubernetes control plane | `false` | Setting to `true` (EKS cluster control plane costs $0.10/hr) |
| `aws_enable_jenkins` | **DO NOT CHANGE** | Self-hosted Jenkins EC2 server | Provisions a dedicated EC2 controller | `false` | Setting to `true` when using GitHub Actions |

---

## Part 6 — Pre-Flight Verification Checklist

Before running Terraform, execute this verification checklist to guarantee zero surprises:

```bash
# 1. Verify AWS credentials and Account ID
aws sts get-caller-identity --query Account --output text

# 2. Verify target region is ap-south-1
aws configure get region

# 3. Verify Docker Desktop daemon is running
docker ps

# 4. Verify Terraform binary is reachable
terraform version

# 5. Verify your tfvars configuration file exists
ls -l terraform/environments/dev/terraform.tfvars
```

#### 🟢 Verification Pass Criteria:
- Command 1 outputs your 12-digit AWS Account ID.
- Command 2 outputs `ap-south-1`.
- Command 3 outputs an empty container list without connection errors.
- Command 4 outputs `Terraform v1.5.0` (or newer).
- Command 5 confirms `terraform.tfvars` is present.

---

## Part 7 — Terraform Fundamentals Explained

### What Is Infrastructure as Code (IaC)?
Instead of clicking around the AWS Web Console for 3 hours and forgetting which buttons you clicked, Terraform lets you define your entire infrastructure in text files (`.tf`). Terraform reads the code and automatically provisions, updates, or deletes resources on AWS with 100% precision.

### The 4 Core Terraform Commands:
1. `terraform init`: Downloads the required cloud provider plugins (like the AWS API driver) and connects to your state storage. Run once at the beginning.
2. `terraform validate`: Scans your code for typos, missing brackets, or syntax errors without touching AWS.
3. `terraform plan`: Performs a read-only preview. Shows you exactly what resources will be created (`+`), modified (`~`), or destroyed (`-`).
4. `terraform apply`: Actually executes the plan, calling AWS APIs to build your live cloud infrastructure.

### What Is Terraform State (`terraform.tfstate`)?
Terraform records every resource ID, IP address, and ARN it creates in a database called the **state file**. If you run `terraform apply` a second time, Terraform compares your local code with the state file and knows that your servers already exist, preventing duplicate creations.

---

## Part 8 — Initialize Remote State Backend (Bootstrap)

To prevent state corruption and allow team collaboration, Terraform stores its state file inside an **Amazon S3 bucket** with encryption and public access blocks, and uses an **Amazon DynamoDB table** for distributed state locking.

### Run the Bootstrap Script

From the repository root, run:

```bash
bash terraform/scripts/bootstrap-state.sh ap-south-1
```

*(On Windows PowerShell, run: `bash terraform/scripts/bootstrap-state.sh ap-south-1` inside Git Bash).*

#### 🟢 Expected Output:
```text
>>> Creating S3 bucket your-org-terraform-state in ap-south-1
    Bucket your-org-terraform-state already exists - skipping create (or Created)
>>> Enabling versioning on your-org-terraform-state
>>> Blocking public access on your-org-terraform-state
>>> Creating DynamoDB table terraform-locks in ap-south-1
>>> Backend bootstrap complete for ap-south-1
```

---

## Part 9 — Understanding the Terraform Execution Plan

Before deploying, navigate to the `terraform/` directory and run the initialization and planning commands:

```bash
cd terraform

# 1. Initialize Terraform with the AWS backend configuration
terraform init \
  -backend-config="cloud/aws/backend.hcl" \
  -backend-config="key=aws/dev/terraform.tfstate" \
  -backend-config="region=ap-south-1"
```

#### 🟢 Expected Output of `terraform init`:
```text
Initializing modules...
- aws in ./cloud/aws
- aws.alb in ./cloud/aws/modules/alb
- aws.compute in ./cloud/aws/modules/compute
- aws.database in ./cloud/aws/modules/database
- aws.ecr in ./cloud/aws/modules/ecr
- aws.security in ./cloud/aws/modules/security
- aws.vpc in ./cloud/aws/modules/vpc

Initializing the backend...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Terraform has been successfully initialized!
```

---

### Run `terraform plan`

```bash
terraform plan \
  -var="cloud=aws" \
  -var-file="environments/dev/terraform.tfvars"
```

### 📋 What Resources Will Be Created? (The 28+ Resources)
Terraform will output a detailed list ending with `Plan: 28 to add, 0 to change, 0 to destroy`. Here is the exact inventory:

1. **VPC Network:**
   - 1× `aws_vpc` (`10.0.0.0/16`)
   - 2× Public Subnets (`10.0.1.0/24`, `10.0.2.0/24`) across AZ `ap-south-1a` and `ap-south-1b`
   - 2× Private Application Subnets (`10.0.11.0/24`, `10.0.12.0/24`)
   - 2× Private Database Subnets (`10.0.21.0/24`, `10.0.22.0/24`)
   - 1× Internet Gateway (connects public subnets to internet)
   - 1× Elastic IP + 1× NAT Gateway (gives private compute instances outbound internet access)
   - 3× Route Tables (Public route to IGW, App route to NAT, DB route strictly local)
2. **Security & Access Control:**
   - 3× Security Groups (`alb-sg`, `app-sg`, `db-sg`) configured in a least-privilege chain
   - 1× AWS WAFv2 WebACL (protects ALB from common web exploits)
   - 1× IAM Role & Instance Profile (allows EC2 to read Secrets Manager and pull ECR images)
3. **Database Layer:**
   - 1× RDS DB Subnet Group
   - 1× `aws_db_instance` (PostgreSQL 16.4 on `db.t3.micro`)
   - 1× AWS Secrets Manager Secret (stores master DB password and JWT secret dynamically)
4. **Container Registry:**
   - 2× ECR Repositories (`secure-ntier-dev-backend`, `secure-ntier-dev-frontend`)
5. **Compute & Ingress Tier:**
   - 1× EC2 Launch Template (Ubuntu 22.04 LTS, Docker, cloud-init `user-data.sh`)
   - 1× Auto Scaling Group (desired capacity: 2 instances spread across AZ a & b)
   - 1× Application Load Balancer (internet-facing, port 80 listener)
   - 1× ALB Target Group (`/health` probe check)
6. **Observability:**
   - 1× CloudWatch Dashboard (`secure-ntier-dev-dashboard`)
   - 3× CloudWatch Metric Alarms (EC2 CPU > 70%, RDS Free Storage, ALB 5xx rate)
   - 1× SNS Topic (`secure-ntier-dev-alerts`) with your email subscription

---

## Part 10 — Deploy Infrastructure (`terraform apply`)

Now, execute the deployment:

```bash
terraform apply \
  -var="cloud=aws" \
  -var-file="environments/dev/terraform.tfvars"
```

Terraform will display the plan and ask:
```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```
Type **`yes`** and press Enter.

### What to Expect During Apply:
- ⏳ **Total Time:** ~10 to 15 minutes.
- 💡 **Why does it take 10 minutes?** The AWS RDS managed PostgreSQL instance and the AWS NAT Gateway take 8–10 minutes to allocate physical hardware and initialize in AWS data centers. **Do NOT press Ctrl+C while RDS is creating!**

#### 🟢 Successful Output:
```text
Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

Outputs:

app_url = "http://secure-ntier-dev-alb-123456789.ap-south-1.elb.amazonaws.com"
asg_name = "secure-ntier-dev-asg"
cloud = "aws"
dashboard_name = "secure-ntier-dev-dashboard"
db_host = <sensitive>
db_secret_ref = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:secure-ntier/dev/credentials-xxxxxx"
image_repository_urls = {
  "backend" = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-backend"
  "frontend" = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-frontend"
}
lb_dns_name = "secure-ntier-dev-alb-123456789.ap-south-1.elb.amazonaws.com"
registry_url = "123456789012.dkr.ecr.ap-south-1.amazonaws.com"
topic_arn = "arn:aws:sns:ap-south-1:123456789012:secure-ntier-dev-alerts"
```

> 💡 **Keep your terminal open!** Note down your `app_url` and `registry_url`. You will use them in the next steps.

---

## Part 11 — Docker Packaging & Local Container Builds

Your AWS infrastructure (VPC, ALB, RDS, ECR) is now live! But your EC2 instances need container images to run. Now we build the Docker images locally.

Navigate back to the project root directory:
```bash
cd ..
```

### 1. Build the Backend Image
The backend image packages Node.js 22, installs production dependencies, and compiles the Express REST API:

```bash
docker build -t secure-ntier-backend:latest -f docker/backend/Dockerfile .
```

### 2. Build the Frontend Image
The frontend image uses a multi-stage build: Stage 1 builds the React/Vite assets, and Stage 2 copies them into a lightweight Nginx web server:

```bash
docker build -t secure-ntier-frontend:latest -f docker/frontend/Dockerfile .
```

### Verify Local Images
```bash
docker images | grep secure-ntier
```
You will see both `secure-ntier-backend` and `secure-ntier-frontend` listed with tag `latest`.

---

## Part 12 — Amazon ECR (Elastic Container Registry) Push

Amazon ECR is your private, secure Docker registry on AWS. We now authenticate Docker to ECR and push our images.

### 1. Retrieve Your AWS Account ID
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-south-1"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Your registry URL is: $REGISTRY"
```

### 2. Authenticate Docker to ECR
```bash
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY"
```
#### 🟢 Expected Output:
```text
Login Succeeded
```

### 3. Tag the Images with ECR Repository Names
```bash
# Tag Backend
docker tag secure-ntier-backend:latest \
  "${REGISTRY}/secure-ntier-dev-backend:latest"

# Tag Frontend
docker tag secure-ntier-frontend:latest \
  "${REGISTRY}/secure-ntier-dev-frontend:latest"
```

### 4. Push Images to ECR
```bash
# Push Backend
docker push "${REGISTRY}/secure-ntier-dev-backend:latest"

# Push Frontend
docker push "${REGISTRY}/secure-ntier-dev-frontend:latest"
```

#### 🟢 Verification via AWS CLI:
```bash
aws ecr list-images --repository-name secure-ntier-dev-backend --region ap-south-1
aws ecr list-images --repository-name secure-ntier-dev-frontend --region ap-south-1
```
Both repositories will show image tag `"latest"` successfully stored in AWS ECR.

---

## Part 13 — Zero-SSH Application Deployment (SSM + ASG Instance Refresh)

### How Our Deployment Works (Zero SSH Required)
In modern cloud engineering, opening SSH (port 22) into servers is an outdated security risk. Instead, this platform uses an **immutable, automated deployment model**:

```text
Developer pushes image to ECR
          │
          ▼
Update AWS Systems Manager (SSM) Parameter Store
(Points to the new ECR image tag: /secure-ntier/dev/backend-image)
          │
          ▼
Trigger AWS Auto Scaling Group Instance Refresh
          │
          ▼
ASG replaces EC2 instances one by one (Rolling Update)
          │
          ▼
New EC2 instance boots ➔ cloud-init user-data.sh runs:
  1. Authenticates to ECR via IAM Instance Profile (Zero hardcoded keys)
  2. Pulls DB credentials from AWS Secrets Manager
  3. Reads image URI from SSM Parameter Store
  4. Launches Docker Compose stack
          │
          ▼
ALB Target Group verifies /health returns HTTP 200
          │
          ▼
ALB directs live user traffic to new instance! 🚀
```

### Execute the Deployment Command

Run the deployment script:
```bash
bash cicd/scripts/deploy-ec2.sh latest ap-south-1 dev secure-ntier
```

#### 🟢 Expected Output:
```text
>>> /secure-ntier/dev/backend-image = 123456789012.dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-backend:latest
>>> /secure-ntier/dev/frontend-image = 123456789012.dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-frontend:latest
>>> Instance refresh started on secure-ntier-dev-asg
```

### Check Instance Refresh Status
You can monitor the rolling replacement of your servers in real time:

```bash
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name secure-ntier-dev-asg \
  --region ap-south-1 \
  --query "InstanceRefreshes[0].{Status:Status,Percentage:PercentageComplete}"
```
*The status will progress from `InProgress` to `Successful` in ~3 to 5 minutes.*

---

## Part 14 — Application Load Balancer (ALB) Routing & Ingress

The Application Load Balancer is the single public entry point for your entire system.

### How Traffic Is Routed:
- Public requests hit the ALB on HTTP port 80.
- AWS WAF inspects headers for rate limiting and SQL injection attacks.
- The ALB evaluates the Target Group (`secure-ntier-dev-tg`).
- The Target Group sends health check pings to `/health` on each EC2 instance every 15 seconds.
- Once an EC2 instance returns HTTP 200, the ALB marks it as `healthy` and routes live traffic to it.

### Retrieve Your Live ALB URL:
```bash
ALB_URL=$(cd terraform && terraform output -raw app_url)
echo "Your live application URL is: $ALB_URL"
```

Open this URL in Google Chrome or your web browser!

---

## Part 15 — Database Tier (RDS PostgreSQL & Secrets Manager)

### Why Is the Database in a Private Subnet?
- The PostgreSQL database is attached to `db_subnet_cidrs` (`10.0.21.0/24` and `10.0.22.0/24`).
- It has `publicly_accessible = false` and has **zero public IP address**.
- Nobody on the public internet can ping, port-scan, or connect to your database directly.

### Security Group Chaining
```text
[ Anyone on Internet ]  ➔  Can ONLY reach ALB on Port 80
                                   │
[ ALB Security Group ]  ➔  Can ONLY reach EC2 App Instances on Port 80
                                   │
[ EC2 App Security Group ] ➔ Can ONLY reach RDS Database on Port 5432
```
The database firewall rule literally states: *“Accept connections on port 5432 ONLY IF the packet originated from an EC2 instance carrying the `app-sg` security group badge.”*

### Dynamic Credentials via AWS Secrets Manager
The database master password is generated randomly by Terraform (`random_password`) and immediately sealed into **AWS Secrets Manager**. It is never written in plain text in any file. When the EC2 server boots up, its IAM instance profile fetches the secret securely over the AWS internal network.

---

## Part 16 — Comprehensive Verification & Testing Runbook

Execute these 6 verification tests to confirm your platform is 100% healthy:

### Test 1: Web Application User Interface
- **Action:** Open `$ALB_URL` in your web browser.
- **Expected Result:** The React application loads with the navigation header, platform status badge, and login form.

---

### Test 2: ALB `/health` JSON Probe
- **Action:** Run curl against the `/health` endpoint:
  ```bash
  curl -s "$ALB_URL/health" | jq .
  ```
- **Expected Result:**
  ```json
  {
    "status": "ok",
    "uptime": 124.5,
    "timestamp": "2026-09-04T10:45:00.000Z",
    "db": "connected",
    "environment": "production"
  }
  ```
  *(Notice `"db": "connected"`. This proves the backend can talk to the private RDS database).*

---

### Test 3: Run the Automated Health Check Script
- **Action:**
  ```bash
  bash scripts/health-check.sh "$ALB_URL"
  ```
- **Expected Result:**
  ```text
  ==> Health check against http://secure-ntier-dev-alb-xxx.ap-south-1.elb.amazonaws.com
    GET /health -> HTTP 200
    body: {"status":"ok","db":"connected"}
    RESULT: PASS (backend reachable, database connected)
  ```

---

### Test 4: Verify EC2 Target Group Health
- **Action:** Check target group registration in AWS CLI:
  ```bash
  TG_ARN=$(aws elbv2 describe-target-groups \
    --names secure-ntier-dev-tg \
    --region ap-south-1 \
    --query "TargetGroups[0].TargetGroupArn" --output text)

  aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --region ap-south-1 \
    --query "TargetHealthDescriptions[*].{Instance:Target.Id,Port:Target.Port,Health:TargetHealth.State}"
  ```
- **Expected Result:**
  ```json
  [
    { "Health": "healthy", "Instance": "i-0a1b2c3d4e5f6g7h8", "Port": 80 },
    { "Health": "healthy", "Instance": "i-0987654321abcdef0", "Port": 80 }
  ]
  ```

---

### Test 5: Verify CloudWatch Observability Dashboard
- **Action:** Open AWS Console > Search **CloudWatch** > Click **Dashboards** > Click `secure-ntier-dev-dashboard`.
- **Expected Result:** Live graphical widgets displaying EC2 CPU Utilization, ALB Request Counts, HTTP 2xx/5xx rates, and RDS Database Connections.

---

### Test 6: Confirm SNS Notification Subscription
- **Action:** Check your email inbox (the address you set in `notification_email`).
- **Expected Result:** An email from `AWS Notifications` with subject *“AWS Notification - Subscription Confirmation”*.
- **Important:** Click the **"Confirm subscription"** link inside the email to activate alarm notifications!

---

## Part 17 — Security Architecture (Defense-in-Depth)

This architecture enforces **Defense-in-Depth across 5 distinct security boundaries**:

| Layer | Security Control | Threat Mitigated |
|---|---|---|
| **1. Perimeter** | AWS WAF v2 attached to ALB | SQL Injection, Cross-Site Scripting (XSS), volumetric DDoS attacks |
| **2. Network** | 3-Tier Private Subnet Topology | Direct scanning or exploitation of compute instances from the internet |
| **3. Firewall** | Chained AWS Security Groups | Lateral movement; only ports 80 and 5432 are open along strict paths |
| **4. Identity** | IAM Roles & AWS Secrets Manager | Zero hardcoded API keys or database passwords on the server disk |
| **5. Storage** | AWS KMS (SSE) Encryption | Data at rest in RDS, EBS root volumes, and S3 state buckets is AES-256 encrypted |

---

## Part 18 — End-to-End User Request Flow

Here is the exact millisecond lifecycle of a user request:

```text
1. 👤 User types http://secure-ntier-dev-alb-xxxx.ap-south-1.elb.amazonaws.com into their browser.
   │
2. 🌐 DNS resolves the ALB address to one of AWS's public IP nodes in ap-south-1.
   │
3. 🛡️ AWS WAF inspects the HTTP request against OWASP Core Rule Sets. (Blocks malformed packets).
   │
4. 🚦 ALB terminates the HTTP connection and evaluates Target Group health.
   │
5. 🔀 ALB picks one of the healthy EC2 instances in private subnet A or B and forwards the packet over port 80.
   │
6. 🐳 Inside the EC2 instance, Nginx reverse proxy receives the packet:
   ├── If requesting static assets (/, /index.html, /assets/*) ➔ Nginx serves React UI instantly.
   └── If requesting API data (/api/*, /health) ➔ Nginx proxies to Node.js backend on port 3000.
   │
7. ⚙️ Node.js backend processes business logic and queries the private PostgreSQL database on port 5432.
   │
8. 🗄️ RDS executes SQL query, returns data securely over private VPC network to Node.js.
   │
9. 📦 Node.js formats JSON response ➔ Nginx ➔ ALB ➔ Browser renders live data for the user!
```

---

## Part 19 — Updating Code & Zero-Downtime Redeployment

When you make changes to the frontend or backend application code, deploy updates without taking the site down:

### 1. Edit Your Code
For example, edit `application/frontend/src/App.jsx` to change a heading or add a button.

### 2. Rebuild the Docker Image
```bash
# Get your ECR registry URL
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"

# Build new version with a new tag (e.g., v2)
docker build -t "${REGISTRY}/secure-ntier-dev-frontend:v2" -f docker/frontend/Dockerfile .
```

### 3. Push the New Tag to ECR
```bash
docker push "${REGISTRY}/secure-ntier-dev-frontend:v2"
```

### 4. Trigger Rolling ASG Update
```bash
# Update SSM parameter to point to v2
aws ssm put-parameter \
  --name "/secure-ntier/dev/frontend-image" \
  --value "${REGISTRY}/secure-ntier-dev-frontend:v2" \
  --type String \
  --overwrite \
  --region ap-south-1

# Trigger zero-downtime rolling instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name secure-ntier-dev-asg \
  --region ap-south-1 \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":120}'
```
*The ASG will launch a new EC2 instance running your updated code, wait for it to pass health checks, route traffic to it, and gracefully terminate the old instance with zero user downtime.*

---

## Part 20 — Troubleshooting & Common Errors

### 1. AWS CLI Errors

#### 🔴 Error: `The security token included in the request is invalid (InvalidClientTokenId)`
- **Why it happens:** The AWS Access Key ID or Secret Key entered during `aws configure` has a typo or was deleted.
- **How to fix:** Generate a new Access Key in the IAM console and re-run `aws configure`.

#### 🔴 Error: `Access Denied (User is not authorized to perform: ...)`
- **Why it happens:** Your IAM user does not have sufficient permissions.
- **How to fix:** In the AWS Console > IAM > Users > `terraform-deployer` > Add permissions > Attach `AdministratorAccess`.

---

### 2. Terraform Errors

#### 🔴 Error: `Error acquiring the state lock: ConditionalCheckFailedException`
- **Why it happens:** A previous Terraform command was cancelled with Ctrl+C, leaving the DynamoDB lock row locked.
- **How to fix:** Force-unlock using the Lock ID shown in the error message:
  ```bash
  terraform force-unlock <LOCK_ID>
  ```

#### 🔴 Error: `DBSubnetGroupDoesNotCoverEnoughAZs: The DB subnet group must cover at least 2 Availability Zones`
- **Why it happens:** `db_subnet_cidrs` were placed into the same Availability Zone.
- **How to fix:** Verify in `terraform.tfvars` that `public_subnet_cidrs`, `app_subnet_cidrs`, and `db_subnet_cidrs` contain 2 distinct subnets corresponding to 2 different AZs.

---

### 3. Docker & ECR Errors

#### 🔴 Error: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`
- **Why it happens:** Docker Desktop application is closed.
- **How to fix:** Open Docker Desktop from your Start Menu / Applications folder and wait until it is running.

#### 🔴 Error: `no basic auth credentials` when running `docker push`
- **Why it happens:** Your temporary ECR authentication token expired (tokens last 12 hours).
- **How to fix:** Re-run the login command:
  ```bash
  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin "$REGISTRY"
  ```

---

### 4. Application Load Balancer & EC2 Errors

#### 🔴 Error: Browser shows `502 Bad Gateway`
- **Why it happens:** The ALB is working, but the EC2 instances are not responding on port 80.
- **Diagnosis:**
  1. Check target health:
     ```bash
     aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region ap-south-1
     ```
  2. Inspect EC2 user-data boot logs via AWS SSM (Zero SSH):
     ```bash
     INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
       --auto-scaling-group-names secure-ntier-dev-asg \
       --region ap-south-1 \
       --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text)

     aws ssm send-command \
       --instance-ids "$INSTANCE_ID" \
       --document-name "AWS-RunShellScript" \
       --parameters 'commands=["tail -n 50 /var/log/user-data.log", "docker ps"]' \
       --region ap-south-1
     ```
- **How to fix:** Verify that container images were pushed to ECR and SSM parameter `/secure-ntier/dev/backend-image` is populated.

#### 🔴 Error: Browser shows `503 Service Unavailable`
- **Why it happens:** No EC2 instances are registered, or all instances failed health checks.
- **How to fix:** Check that `asg_desired_capacity` is at least `1` in `terraform.tfvars` and run `terraform apply`.

---

## Part 21 — 🧹 Complete Infrastructure Teardown (`terraform destroy`)

To permanently stop all AWS billing after you have tested the application, run Terraform destroy.

### 1. Destroy AWS Infrastructure
Navigate to the `terraform/` folder and execute:

```bash
cd terraform

terraform destroy \
  -var="cloud=aws" \
  -var-file="environments/dev/terraform.tfvars"
```

Terraform will ask for confirmation:
```text
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```
Type **`yes`** and press Enter.

⏳ *Wait ~10 to 12 minutes for AWS to delete the RDS database, NAT Gateway, ALB, and EC2 instances.*

#### 🟢 Expected Output:
```text
Destroy complete! Resources: 28 destroyed.
```

---

### 2. Clean Up Remaining Non-Terraform Assets

Terraform deletes everything it created, but safety rules require two manual verifications:

#### 🧹 A. Delete Container Images in ECR (if any remain)
```bash
aws ecr batch-delete-image \
  --repository-name secure-ntier-dev-backend \
  --image-ids imageTag=latest \
  --region ap-south-1 2>/dev/null || true

aws ecr batch-delete-image \
  --repository-name secure-ntier-dev-frontend \
  --image-ids imageTag=latest \
  --region ap-south-1 2>/dev/null || true
```

#### 🧹 B. Delete S3 State Bucket (if deleting permanent state)
*Only do this if you are completely finished with the project:*
```bash
STATE_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'terraform-state')].Name" --output text)
aws s3 rb "s3://$STATE_BUCKET" --force 2>/dev/null || true
```

---

### 3. Verify $0 Incurred in AWS Console
Open the [AWS Management Console](https://console.aws.amazon.com/) in region `ap-south-1`:
- **EC2 Console:** Confirm **0** Running Instances and **0** Load Balancers.
- **VPC Console:** Confirm **0** NAT Gateways and **0** Elastic IPs.
- **RDS Console:** Confirm **0** Databases.
- **Billing Console:** Check the Billing Dashboard after 24 hours to confirm charges have ceased.

---

## Part 22 — Fast-Track One-Command Deployment

Once you understand the architecture, you can execute the entire lifecycle (Bootstrap + Terraform + Docker Build + ECR Push + Deploy + Smoke Test) with **a single automated command**:

```bash
# Ensure AWS credentials are configured, then run:
bash scripts/deploy-to-ec2.sh ap-south-1 dev secure-ntier
```

This master script automatically executes Steps 8 through 16 sequentially, printing colored status updates at each gate, and finishes with a live smoke test!

---

## Part 23 — Local Development Stack (100% Free, Zero AWS)

You can run and develop the entire 3-tier architecture locally on your laptop without an AWS account or internet connection:

### 1. Start the Local Docker Stack
```bash
cd docker
docker compose up --build -d
```

### 2. Test the Local Application
- **Frontend UI:** Open [http://localhost](http://localhost) in your browser.
- **Backend API:** Open [http://localhost/api/items](http://localhost/api/items).
- **Health Check:** Run `curl http://localhost/health`.
  ```json
  {"status":"ok","db":"connected"}
  ```

### 3. Stop Local Stack
```bash
docker compose down
# (Add -v to wipe the local database volume: docker compose down -v)
```

---

## Part 24 — Command Cheat Sheet

Bookmark this section for quick copy-pasting during operations:

### 🛠️ Configuration & Preflight
```bash
# Configure AWS CLI
aws configure

# Verify Identity
aws sts get-caller-identity

# Copy example variables
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

### 🏗️ Terraform Lifecycle
```bash
cd terraform

# Bootstrap remote state
bash scripts/bootstrap-state.sh ap-south-1

# Initialize
terraform init -backend-config="cloud/aws/backend.hcl" -backend-config="key=aws/dev/terraform.tfstate" -backend-config="region=ap-south-1"

# Plan
terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"

# Apply
terraform apply -var="cloud=aws" -var-file="environments/dev/terraform.tfvars" -auto-approve

# Output Values
terraform output

# Destroy
terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars" -auto-approve
```

### 🐳 Docker & ECR
```bash
# Build
docker build -t secure-ntier-backend:latest -f docker/backend/Dockerfile .
docker build -t secure-ntier-frontend:latest -f docker/frontend/Dockerfile .

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com

# Push
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-backend:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com/secure-ntier-dev-frontend:latest
```

### 🧪 Verification
```bash
# Run Health Check
bash scripts/health-check.sh "$ALB_URL"

# Describe Target Health
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region ap-south-1
```

---

## Part 25 — DevOps & Cloud Glossary

| Term | Simple Definition |
|---|---|
| **VPC (Virtual Private Cloud)** | Your private, isolated data center inside Amazon Web Services. |
| **Subnet** | A subdivided portion of a VPC with specific IP ranges and routing rules (Public or Private). |
| **CIDR Block** | Standard notation specifying an IP address range (e.g. `10.0.0.0/16` gives 65,536 addresses). |
| **Internet Gateway (IGW)** | A redundant VPC router connecting public subnets directly to the open internet. |
| **NAT Gateway** | Allows servers in private subnets to download updates from the internet while blocking anyone outside from connecting in. |
| **ALB (Application Load Balancer)** | Smart layer-7 traffic distributor that receives incoming HTTP/HTTPS traffic and routes it to healthy web servers. |
| **Target Group** | A collection of backend targets (EC2 instances) that receive forwarded traffic from a Load Balancer. |
| **EC2 (Elastic Compute Cloud)** | Virtual servers (VMs) running Linux in the AWS cloud. |
| **Auto Scaling Group (ASG)** | Automatic manager that scales EC2 instances up or down based on load and automatically replaces dead servers. |
| **Launch Template** | The blueprint specifying the AMI image, instance size, and boot script used whenever the ASG launches an EC2 instance. |
| **User Data (cloud-init)** | A shell script executed automatically as `root` the very first time an EC2 virtual machine boots up. |
| **RDS (Relational Database Service)** | Fully managed database service on AWS handling automated backups, software patching, and multi-AZ replication. |
| **ECR (Elastic Container Registry)** | Highly available, private Amazon Docker container image registry. |
| **IAM (Identity & Access Management)** | AWS security system managing users, permissions, and service-to-service roles. |
| **Secrets Manager** | Encrypted vault service that stores, rotates, and dispenses database passwords and API tokens. |
| **CloudWatch** | AWS monitoring and logging service that captures metrics, displays graphs, and triggers alarms. |
| **SNS (Simple Notification Service)** | Publisher/subscriber messaging service that sends SMS or email alerts when CloudWatch alarms trigger. |
| **WAF (Web Application Firewall)** | Cloud firewall service that filters malicious web traffic such as SQL injections and cross-site scripting (XSS). |

---

### 🎉 Congratulations!
You have successfully deployed a production-grade, highly available, secure 3-Tier Web Application on Amazon Web Services using modern Infrastructure as Code and automated container deployments!

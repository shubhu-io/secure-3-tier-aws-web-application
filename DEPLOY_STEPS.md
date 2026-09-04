# 🚀 How to Deploy SecureNTier to AWS EC2
### *The Ultimate Beginner-Friendly, Step-by-Step Guide (Zero Prior Experience Needed!)*

> 📖 **What this guide does:** Takes your code from your computer and deploys it live on the internet using Amazon Web Services (AWS). When you are done, your app will be running on real cloud servers with an **Application Load Balancer (ALB)**, an **Auto Scaling Group of EC2 servers**, and a **PostgreSQL RDS Database**!
>
> ⏱️ **Total time needed:** ~20 to 30 minutes (about 5 minutes of typing, and 15–20 minutes of AWS doing all the building in the background).
>
> 💰 **Cost:** About **$0.05 to $0.10 per hour** while running for testing. **When you follow Step 14 at the end to destroy it, your charges stop immediately!**

---

## 📚 Table of Contents
1. [🛒 Part 0: What You Need & Tool Setup](#-part-0--what-you-need--tool-setup)
2. [🔑 Part 1: Connect Your AWS Account](#-part-1--connect-your-aws-account)
3. [📝 Part 2: Configure Your Settings](#-part-2--configure-your-settings)
4. [🏗️ Part 3: Deploy Everything to AWS with One Command](#-part-3--deploy-everything-to-aws-with-one-command)
5. [🧪 Part 4: Test and Explore Your Live App](#-part-4--test-and-explore-your-live-app)
6. [🔄 Part 5: Updating Your App After Making Code Changes](#-part-5--updating-your-app-after-making-code-changes)
7. [💻 Part 6: Run Locally (100% Free, No AWS Needed)](#-part-6--run-locally-100-free-no-aws-needed)
8. [💥 Part 7: Delete Everything to Stop AWS Charges](#-part-7--delete-everything-to-stop-aws-charges)
9. [🆘 Part 8: Troubleshooting & Frequently Asked Questions](#-part-8--troubleshooting--frequently-asked-questions)
10. [📋 Part 9: Quick Command Cheat Sheet](#-part-9--quick-command-cheat-sheet)

---

## 🛒 PART 0 — What You Need & Tool Setup

Before we start, your computer needs 4 free tools. Think of these like your kitchen utensils before cooking.

### Tool Overview

| Tool | What it does | Cost | Download Link |
|---|---|---|---|
| **Git & Git Bash** | Downloads code & gives you a Linux-like terminal on Windows | ✅ Free | [git-scm.com/downloads](https://git-scm.com/downloads) |
| **AWS CLI** | Official Amazon tool to control AWS from your computer | ✅ Free | [Download Installer](https://awscli.amazonaws.com/AWSCLIV2.msi) |
| **Terraform** | Reads code files and automatically creates servers on AWS | ✅ Free | [terraform.io/downloads](https://developer.hashicorp.com/terraform/install) |
| **Docker Desktop** | Packages your code into lightweight containers | ✅ Free | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |

---

### Step-by-Step Installation for Windows

#### 1. Git & Git Bash (Recommended Terminal for Windows)
- If you don't have it, download and run the installer from [git-scm.com](https://git-scm.com/downloads).
- Leave all default options checked during installation.
- 💡 **How to open Git Bash inside your project:**
  1. Open your File Explorer and navigate to your project folder:
     `d:\Codeing\github\devops project\secure-ntier-cloud-platform`
  2. Right-click anywhere in the blank space inside the folder.
  3. Click **"Open Git Bash here"**.
  4. A black terminal window will open, already located inside your project!

#### 2. AWS CLI (v2)
- Download the official installer: [AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi)
- Double-click the downloaded `.msi` file, click **Next** -> **Accept terms** -> **Next** -> **Install** -> **Finish**.
- To verify, close your terminal, open a new Git Bash or Command Prompt, and run:
  ```bash
  aws --version
  ```
  *(You should see something like: `aws-cli/2.x.x Python/3.x.x ...`)*

#### 3. Terraform
- Download the Windows 64-bit zip from HashiCorp: [Terraform Downloads](https://developer.hashicorp.com/terraform/install).
- Extract the downloaded `.zip` file. You will see a single file named `terraform.exe`.
- Move `terraform.exe` into a folder on your system PATH (e.g. `C:\Windows\System32`), or create a folder like `C:\terraform`, place it there, and add `C:\terraform` to your Windows Environment Variables PATH.
- To verify:
  ```bash
  terraform -version
  ```
  *(You should see: `Terraform v1.x.x`)*

#### 4. Docker Desktop
- Download from [Docker Desktop](https://www.docker.com/products/docker-desktop/).
- Run the installer. If it asks to enable WSL 2 features, check the box and allow it.
- Restart your computer if prompted.
- Launch **Docker Desktop** from your Start Menu.
- ⚠️ **Wait until the whale icon in the bottom system tray turns solid (not animated) and says "Docker Desktop is running".** Docker must be running before you can build images!
- To verify:
  ```bash
  docker --version
  ```

---

### Step-by-Step Installation for macOS / Linux

- **macOS (using Homebrew):**
  ```bash
  brew install awscli terraform
  brew install --cask docker
  ```
- **Ubuntu / Debian Linux:**
  ```bash
  # AWS CLI
  sudo apt-get update && sudo apt-get install -y awscli jq curl unzip
  # Terraform
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt-get install terraform
  ```

---

## 🔑 PART 1 — Connect Your AWS Account

Before your computer can create servers on AWS, AWS needs to verify who you are. We do this using **AWS Access Keys**.

### Step 1: Log in to AWS and Create Access Keys

1. Open your web browser and log in to the [AWS Management Console](https://console.aws.amazon.com).
2. Look at the top-right corner of the page where your username / account name is displayed.
3. Click on your **Account Name**, then click **"Security credentials"**.
4. Scroll down until you see the section titled **"Access keys"**.
5. Click the button that says **"Create access key"**.
6. On the next screen, select **"Command Line Interface (CLI)"**.
7. Check the confirmation checkbox at the bottom (*"I understand the above recommendation..."*) and click **"Next"**.
8. (Optional) Enter a description tag like `my-laptop`, then click **"Create access key"**.
9. ⚠️ **CRITICAL MOMENT:** AWS will show you two keys:
   - **Access Key ID:** A string of capital letters and numbers starting with `AKIA...` (e.g. `AKIAIOSFODNN7EXAMPLE`)
   - **Secret Access Key:** A longer string of random characters (e.g. `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
   - Click **"Download .csv file"** or copy both keys into a private text file. *You will never be able to see the Secret Access Key again after you leave this page!*
10. Click **"Done"**.

> 💡 **Best Practice — Set a $5 Budget Alert:**
> In the AWS search bar at the top, type **"Budgets"**, click **AWS Budgets** -> **"Create budget"** -> choose **"Zero spend budget"** or **"Monthly cost budget"** with an amount of `$5.00`, and enter your email. If your bill ever reaches $5, AWS will instantly email you!

---

### Step 2: Configure AWS on Your Computer

Open your terminal (**Git Bash** on Windows, or standard Terminal on Mac/Linux) and type:

```bash
aws configure
```

The terminal will ask you 4 questions one by one. Paste your details and press Enter after each:

```text
AWS Access Key ID [None]: PASTE_YOUR_ACCESS_KEY_ID_HERE
AWS Secret Access Key [None]: PASTE_YOUR_SECRET_ACCESS_KEY_HERE
Default region name [None]: eu-west-1
Default output format [None]: json
```

> 🌍 **Which Region Should You Choose?**
> You can pick any region close to your physical location:
> - **India / South Asia:** `ap-south-1` (Mumbai)
> - **Europe / UK:** `eu-west-1` (Ireland) or `eu-central-1` (Frankfurt)
> - **North America (East):** `us-east-1` (N. Virginia) or `us-east-2` (Ohio)
> - **North America (West):** `us-west-2` (Oregon)
> - **Southeast Asia:** `ap-southeast-1` (Singapore)

---

### Step 3: Test that AWS is Connected

Run this command:

```bash
aws sts get-caller-identity
```

✅ **Expected Result:**
```json
{
    "UserId": "AIDAXAMPLEUSERID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

If you see your Account number and ARN, **congratulations! Your computer is securely connected to AWS!**

---

## 📝 PART 2 — Configure Your Settings

Terraform uses a settings file (`terraform.tfvars`) to know what region to deploy to and where to send alerts.

### Step 4: Copy the Example Configuration File

Make sure you are in the root directory of the project:
`d:\Codeing\github\devops project\secure-ntier-cloud-platform`

**In Git Bash or Linux/macOS:**
```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

**Or in Windows Command Prompt (cmd):**
```cmd
copy terraform\environments\dev\terraform.tfvars.example terraform\environments\dev\terraform.tfvars
```

---

### Step 5: Edit `terraform.tfvars` with Your Values

Open `terraform/environments/dev/terraform.tfvars` in VS Code, Notepad, or any text editor.

You only need to customize two lines:

```hcl
project_name = "secure-ntier"
environment  = "dev"
aws_region   = "eu-west-1"          # 👈 1. Set to your AWS region (e.g. "ap-south-1", "us-east-1", "eu-west-1")

# ... other settings can stay as defaults ...

notification_email = "your-email@example.com"   # 👈 2. Set to your REAL email for AWS alarms
```

#### What are the other settings in this file?
- `aws_instance_type = "t3.micro"`: The virtual server size. `t3.micro` has 2 vCPUs, 1 GB RAM, and is free-tier eligible.
- `asg_min_size = 2`, `asg_max_size = 4`, `asg_desired_capacity = 2`: Keeps at least 2 servers running across different data centers (Availability Zones) for high availability.
- `aws_db_instance_class = "db.t3.micro"`: PostgreSQL database size.
- `skip_final_snapshot = true`: When we delete the database later, it won't waste time taking a 15-minute backup.

Save the file (**Ctrl + S** or **Cmd + S**).

---

## 🏗️ PART 3 — Deploy Everything to AWS with One Command

Now comes the exciting part! A single automated script will build the entire cloud architecture for you.

### Step 6: Make Sure Docker Desktop is Running

Check the bottom-right taskbar on Windows or menu bar on Mac:
- Ensure the Docker whale icon is steady and not animated.
- If not running, open **Docker Desktop** and wait 30 seconds.

---

### Step 7: Run the Deployment

In **Git Bash** (or terminal), run:

```bash
make deploy-aws
```

> 💡 **Don't have `make` installed? No problem!**
> You can run the exact same script directly using bash:
> ```bash
> bash scripts/deploy-to-ec2.sh
> ```
> *(Or specify a custom region: `bash scripts/deploy-to-ec2.sh ap-south-1`)*

---

### ⏳ What Is Happening During Deployment? (Takes ~15–20 minutes)

You will see clean, colored log output scrolling in your terminal. Here is exactly what is happening in each stage:

```text
╔══════════════════════════════════════════════════════════╗
║      secure-ntier  —  AWS EC2 End-to-End Deploy          ║
╚══════════════════════════════════════════════════════════╝
```

1. **Step 1/7 — Preflight checks:**
   Verifies that AWS CLI, Terraform, and Docker are ready, and tests your AWS authentication.
2. **Step 2/7 — Bootstrap Terraform state backend:**
   Creates a private **Amazon S3 bucket** to store Terraform state files and an **Amazon DynamoDB table** for state locking so multiple people cannot corrupt the infrastructure at the same time.
3. **Step 3/7 — Terraform init, plan, apply:**
   Terraform talks to AWS and provisions **28 cloud resources**:
   - A secure **Virtual Private Cloud (VPC)** with 6 isolated subnets (2 public, 2 application, 2 database).
   - An **Internet Gateway** and **NAT Gateway** for routing traffic.
   - An **Application Load Balancer (ALB)** with Target Groups and Health Checks.
   - An **Auto Scaling Group (ASG)** with an EC2 Launch Template running Amazon Linux 2023.
   - A managed **Amazon RDS PostgreSQL database** in the private database subnet.
   - An **AWS Secrets Manager** secret for the database credentials.
   - **ECR Repositories** for storing container images.
   - **CloudWatch Alarms** and an **SNS Topic** connected to your email.
   *(Note: RDS Database creation takes about 7 to 10 minutes. This is normal AWS behavior!)*
4. **Step 4/7 — Build Docker images:**
   Builds the production container for the **frontend** web application and the **backend** Node.js API.
5. **Step 5/7 — Push images to ECR:**
   Logs in to Amazon Elastic Container Registry (ECR) and uploads both container images.
6. **Step 6/7 — Deploy (SSM + ASG Instance Refresh):**
   Updates AWS Systems Manager Parameter Store with the latest container tags and triggers an **Auto Scaling Group Rolling Instance Refresh**. The EC2 instances pull the new container images and launch them via Docker Compose.
7. **Step 7/7 — Smoke test:**
   The script repeatedly pings the Application Load Balancer URL until the application responds with HTTP 200 OK!

---

### ✅ How You Know It Succeeded

When the script finishes, you will see a banner like this:

```text
╔══════════════════════════════════════════════════════════╗
║           ✅  Deployment complete!                       ║
╚══════════════════════════════════════════════════════════╝

[INFO]  App URL:  http://secure-ntier-dev-alb-123456789.eu-west-1.elb.amazonaws.com
[INFO]  Health:   http://secure-ntier-dev-alb-123456789.eu-west-1.elb.amazonaws.com/health
[INFO]  Tear down: make tf-destroy   (or cd terraform && terraform destroy)
```

🎉 **Congratulations! Your application is now live on the World Wide Web!**

---

## 🧪 PART 4 — Test and Explore Your Live App

### Step 8: Visit Your Application in the Browser

1. Copy the **App URL** from the terminal output (e.g. `http://secure-ntier-dev-alb-XXXX.eu-west-1.elb.amazonaws.com`).
2. Open Chrome, Firefox, Edge, or Safari, and paste the URL.
3. You will see the **SecureNTier Live Dashboard**!
4. Click on **Health Check** or navigate to:
   ```text
   http://YOUR_ALB_URL/health
   ```
   You should see:
   ```json
   {
     "status": "ok",
     "db": "connected",
     "environment": "production"
   }
   ```
   - `"status": "ok"` means the web server and load balancer are communicating.
   - `"db": "connected"` means the backend EC2 server successfully connected across private subnets to the PostgreSQL RDS database!

---

### Step 9: Confirm Your Email Alerts

Check the inbox of the email address you put in `notification_email`. You will see an email from **AWS Notifications** with the subject:
`"AWS Notification - Subscription Confirmation"`

Click the link inside the email that says **"Confirm subscription"**. Now, if any server ever fails or CPU exceeds 80%, AWS will notify you!

---

### Step 10: See Your Resources in the AWS Console (Optional)

Take a tour of what you just built:
1. **EC2 Instances:**
   Go to [AWS Console -> EC2](https://console.aws.amazon.com/ec2) -> click **"Instances"**.
   You will see **2 running instances** with names like `secure-ntier-dev-asg`.
2. **Load Balancer:**
   Click **"Load Balancers"** on the left menu. You will see `secure-ntier-dev-alb`.
3. **Target Groups:**
   Click **"Target Groups"** -> click `secure-ntier-dev-tg` -> click the **"Targets"** tab.
   You will see both EC2 instances with health status **Healthy** (in green) ✅!
4. **RDS Database:**
   In the top search bar, type `RDS` -> click **Databases**. You will see `secure-ntier-dev-db` with status **Available**!

---

## 🔄 PART 5 — Updating Your App After Making Code Changes

Whenever you edit frontend files in `application/frontend/` or backend code in `application/backend/`, you do **NOT** need to rebuild the entire AWS infrastructure!

Simply run:

```bash
make push-aws
```
*(Or if not using make: `bash cicd/scripts/build-and-push.sh $(git rev-parse --short HEAD) eu-west-1 dev secure-ntier && bash cicd/scripts/deploy-ec2.sh $(git rev-parse --short HEAD) eu-west-1 dev secure-ntier`)*

This builds new Docker images, pushes them to ECR, and triggers a **zero-downtime rolling update** across your EC2 instances.

---

## 💻 PART 6 — Run Locally (100% Free, No AWS Needed)

If you want to test and develop on your own laptop without deploying to AWS:

### Start the Local Stack

```bash
make local-up
```
*(Or: `bash scripts/local-up.sh`)*

Open your browser:
- **Frontend App:** [http://localhost](http://localhost)
- **Backend API:** [http://localhost:3000](http://localhost:3000)
- **Health Check:** [http://localhost:3000/health](http://localhost:3000/health)

### Stop the Local Stack

```bash
make local-down
```

To stop and also delete local database storage:
```bash
make local-reset
```

---

## 💥 PART 7 — Delete Everything to Stop AWS Charges

> ⚠️ **IMPORTANT RULE OF CLOUD COMPUTING:**
> Cloud providers bill you for every hour resources exist. When you are finished showing off your project or testing it, **always delete your resources**!

### Step 11: Run the Destroy Command

In **Git Bash** (or terminal), run:

```bash
make tf-destroy
```

> 💡 **If not using `make`:**
> ```bash
> cd terraform
> terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
> cd ..
> ```

1. Terraform will list all 28 resources it is about to delete.
2. At the prompt:
   ```text
   Do you really want to destroy all resources?
     Enter a value:
   ```
3. Type: `yes` and press Enter.
4. ⏳ Wait 5–10 minutes.
5. When complete, you will see:
   ```text
   Destroy complete! Resources: 28 destroyed.
   ```
6. 💸 **All AWS charges stop immediately!**

---

## 🆘 PART 8 — Troubleshooting & Frequently Asked Questions

### ❓ 1. `'make' is not recognized as an internal or external command`
- **Cause:** Windows Command Prompt does not have `make` installed.
- **Fix:** Either use **Git Bash** (where bash scripts run natively), or run the bash command directly:
  ```bash
  bash scripts/deploy-to-ec2.sh
  ```

### ❓ 2. `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`
- **Cause:** Docker Desktop is not running.
- **Fix:** Open **Docker Desktop** from your Windows Start Menu or Mac Applications. Wait 30 seconds until the bottom-left whale icon shows green "Engine running", then retry your command.

### ❓ 3. `Error: No valid credential sources found` or `InvalidClientTokenId`
- **Cause:** AWS CLI keys are missing or invalid.
- **Fix:** Re-run `aws configure` and carefully paste your **Access Key ID** and **Secret Access Key** without any leading/trailing spaces. Test with `aws sts get-caller-identity`.

### ❓ 4. `Error: BucketAlreadyExists` or `BucketAlreadyOwnedByOther`
- **Cause:** Amazon S3 bucket names must be globally unique across all AWS accounts in the world! If someone else uses `secure-ntier-dev-tfstate`, AWS rejects it.
- **Fix:** Set a custom state bucket name with your name or random digits:
  ```bash
  export STATE_BUCKET="myname-securentier-tfstate-12345"
  bash scripts/deploy-to-ec2.sh
  ```

### ❓ 5. `Error acquiring the state lock`
- **Cause:** A previous deployment crashed or was canceled with Ctrl+C while Terraform had locked the DynamoDB table.
- **Fix:** Copy the Lock ID shown in the error message (e.g. `b4a2...`), then run:
  ```bash
  cd terraform
  terraform force-unlock <LOCK_ID>
  cd ..
  ```

### ❓ 6. `The specified location-constraint is not valid`
- **Cause:** AWS S3 has a legacy rule where `us-east-1` must not specify a location constraint.
- **Fix:** Our script `terraform/scripts/bootstrap-state.sh` handles this automatically. Simply update your repository to the latest version.

### ❓ 7. Smoke test timed out or ALB returns 502 Bad Gateway
- **Cause:** The EC2 instances are still booting up, pulling Docker images, or the database is finishing initial seeding.
- **Fix:** Wait 2–3 minutes and refresh your browser. If it is still not responding, connect to the EC2 instance via AWS Systems Manager Session Manager or view instance logs:
  - Go to AWS Console -> EC2 -> Instances -> select instance -> click **Actions** -> **Monitor and troubleshoot** -> **Get system log**.

---

## 📋 PART 9 — Quick Command Cheat Sheet

| Task | Command (with Make) | Alternative (Direct Bash) |
|---|---|---|
| **Deploy whole stack to AWS** | `make deploy-aws` | `bash scripts/deploy-to-ec2.sh` |
| **Deploy to custom region** | `make deploy-aws REGION=ap-south-1` | `bash scripts/deploy-to-ec2.sh ap-south-1` |
| **Update code on AWS (fast)** | `make push-aws` | `make push-aws` |
| **Start local test stack** | `make local-up` | `bash scripts/local-up.sh` |
| **Stop local test stack** | `make local-down` | `docker compose -f docker/docker-compose.yml down` |
| **Wipe local database** | `make local-reset` | `docker compose -f docker/docker-compose.yml down -v` |
| **Preview Terraform changes** | `make tf-plan` | `cd terraform && terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"` |
| **Apply Terraform changes** | `make tf-apply` | `cd terraform && terraform apply -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"` |
| **💥 Delete AWS stack (Stop $)** | `make tf-destroy` | `cd terraform && terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"` |

---

## 🗺️ Visual Architecture Diagram

This is what you built on AWS:

```text
                           [ USER BROWSER ]
                                  │
                                  ▼
                ┌───────────────────────────────────┐
                │   AWS Application Load Balancer   │ (Public Subnet)
                │     (Port 80 HTTP / 443 HTTPS)    │
                └─────────────────┬─────────────────┘
                                  │
                 Round-robin load balancing
                                  │
        ┌─────────────────────────┴─────────────────────────┐
        ▼                                                   ▼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│       EC2 Instance 1          │   │       EC2 Instance 2          │
│   (Private App Subnet AZ-A)   │   │   (Private App Subnet AZ-B)   │
│ ┌───────────┐   ┌───────────┐ │   │ ┌───────────┐   ┌───────────┐ │
│ │ Frontend  │   │  Backend  │ │   │ │ Frontend  │   │  Backend  │ │
│ │ Container │   │ Container │ │   │ │ Container │   │ Container │ │
│ └───────────┘   └─────┬─────┘ │   │ └───────────┘   └─────┬─────┘ │
└───────────────────────┼───────┘   └───────────────────────┼───────┘
                        │                                   │
                        └─────────────────┬─────────────────┘
                                          │
                                          ▼
                        ┌───────────────────────────────────┐
                        │      PostgreSQL RDS Database      │
                        │      (Private Database Subnet)    │
                        └───────────────────────────────────┘
```

---

*Made with ❤️ for DevOps learners. If you ran into any unexpected errors, review the [Troubleshooting](#-part-8--troubleshooting--frequently-asked-questions) section above!*

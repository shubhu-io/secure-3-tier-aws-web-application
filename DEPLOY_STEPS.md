# 🚀 How to Deploy SecureNTier to AWS EC2
### *So simple, anyone can do it!*

> 📖 **What this guide does:** Takes your code from your computer and puts it live on the internet using Amazon Web Services (AWS). When done, anyone in the world can visit your app!

> ⏱️ **How long it takes:** About 20–30 minutes total (mostly waiting for AWS)

> 💰 **Cost:** About $2–3 per day if you leave it running. **Always destroy when done to stop charges!**

---

## 🛒 What You Need Before Starting

Think of these like ingredients before cooking. Get all of them first!

| Thing | What it is | Where to get it | Free? |
|---|---|---|---|
| **AWS Account** | Your Amazon cloud account | [aws.amazon.com](https://aws.amazon.com) → Create account | ✅ Free to create |
| **AWS CLI** | A tool to talk to AWS from your computer | [Download here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | ✅ Free |
| **Terraform** | A tool that builds your cloud setup | [Download here](https://developer.hashicorp.com/terraform/install) | ✅ Free |
| **Docker Desktop** | A tool to package your app | [Download here](https://www.docker.com/products/docker-desktop/) | ✅ Free |
| **Git** | Already on your computer | Usually pre-installed | ✅ Free |

---

## ✅ PART 1 — Check Everything is Ready

### Step 1 — Open your Terminal

> **Windows:** Press `Win + R`, type `cmd`, press Enter
> **Mac:** Press `Cmd + Space`, type `Terminal`, press Enter

### Step 2 — Go to the project folder

Type this and press Enter:
```
cd "d:\Codeing\github\devops project\secure-ntier-cloud-platform"
```

> 💡 **What this does:** Moves you into the project folder, like opening a drawer

### Step 3 — Check all tools are installed

Type this and press Enter:
```
make prereqs
```

You should see `[OK]` next to every tool like this:
```
[OK]   aws
[OK]   terraform
[OK]   docker
[OK]   git
[OK]   jq
```

> ❌ **If you see `[MISS]`** next to something — click the download link in the table above and install that tool, then run this step again.

---

## 🔑 PART 2 — Connect to Your AWS Account

### Step 4 — Create AWS Access Keys

> 🤔 **Why?** Your computer needs a "password" to talk to AWS. These are called Access Keys.

1. Go to [AWS Console](https://console.aws.amazon.com) and log in
2. Click your **name** in the top-right corner
3. Click **"Security credentials"**
4. Scroll down to **"Access keys"**
5. Click **"Create access key"**
6. Choose **"Command Line Interface (CLI)"** → tick the box → click **"Next"**
7. Click **"Create access key"**
8. ⚠️ **COPY BOTH KEYS NOW** — you can only see the secret key once!
   - Access Key ID (looks like: `AKIAIOSFODNN7EXAMPLE`)
   - Secret Access Key (looks like: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

### Step 5 — Give your computer the AWS keys

Type this and press Enter:
```
aws configure
```

It will ask you 4 questions. Answer them like this:

```
AWS Access Key ID:       PASTE_YOUR_ACCESS_KEY_HERE
AWS Secret Access Key:   PASTE_YOUR_SECRET_KEY_HERE
Default region name:     eu-west-1
Default output format:   json
```

> 💡 **Which region?** Type the one closest to you:
> - India → `ap-south-1`
> - USA East → `us-east-1`
> - UK/Europe → `eu-west-1`

### Step 6 — Test that AWS is connected

Type this and press Enter:
```
aws sts get-caller-identity
```

✅ **Good result** — you'll see something like:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/yourname"
}
```

❌ **Error result** — go back to Step 4 and make sure you copied the keys correctly.

---

## 📝 PART 3 — Fill in Your Settings

### Step 7 — Copy the settings template

> 🤔 **Why?** The app needs to know small details like your email and AWS region.

**On Windows** — type this:
```
copy terraform\environments\dev\terraform.tfvars.example terraform\environments\dev\terraform.tfvars
```

**On Mac/Linux** — type this:
```
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

### Step 8 — Open and edit the settings file

Open this file in Notepad (or any text editor):
```
terraform\environments\dev\terraform.tfvars
```

Find these 2 lines and change them:

**Change line 1** — your AWS region (same one you used in Step 5):
```
aws_region = "eu-west-1"
```
Change `eu-west-1` to your region. Examples:
- India → `"ap-south-1"`
- USA → `"us-east-1"`

**Change line 2** — your email (for getting alerts if something breaks):
```
notification_email = "you@example.com"
```
Change `you@example.com` to **your real email**.

**Save the file** (Ctrl+S on Windows, Cmd+S on Mac)

---

## 🏗️ PART 4 — Build Everything on AWS

### Step 9 — Run the magic deploy command

> 🤔 **What this does:** This ONE command does everything:
> 1. Creates your cloud storage on AWS
> 2. Builds your entire server setup (network, load balancer, database, servers)
> 3. Packages your app into a container
> 4. Uploads your app to AWS
> 5. Makes your servers use the new app
> 6. Tests that everything works

Type this and press Enter:
```
make deploy-aws
```

> ⏳ **Now wait!** This takes **12–20 minutes**. Go make a cup of tea! ☕
>
> You'll see lots of text scrolling. This is normal. Look for these markers showing progress:
> ```
> ━━━ Step 1/7 — Preflight checks
> ━━━ Step 2/7 — Bootstrap Terraform state backend
> ━━━ Step 3/7 — Terraform init, plan, apply
> ━━━ Step 4/7 — Build Docker images
> ━━━ Step 5/7 — Push images to ECR
> ━━━ Step 6/7 — Deploy: update SSM + trigger ASG
> ━━━ Step 7/7 — Smoke test
> ```

### ✅ How you know it worked

At the very end you'll see:
```
╔══════════════════════════════════════════════════════════╗
║           ✅  Deployment complete!                       ║
╚══════════════════════════════════════════════════════════╝

[INFO]  App URL:  http://secure-ntier-dev-alb-XXXXXXX.eu-west-1.elb.amazonaws.com
[INFO]  Health:   http://secure-ntier-dev-alb-XXXXXXX.eu-west-1.elb.amazonaws.com/health
```

> 🎉 **Your app is now LIVE on the internet!** Copy that App URL — it's your website address!

---

## 🧪 PART 5 — Check That it's Working

### Step 10 — Visit the health page

Copy the URL from Step 9 (the one ending in `.elb.amazonaws.com`)

Open your browser and go to:
```
http://YOUR_URL_HERE/health
```

You should see:
```json
{"status":"ok","db":"connected","environment":"production"}
```

> ✅ **`"status":"ok"` means everything is working perfectly!**
> ❌ **If you see an error** — wait 2 more minutes and try again. Sometimes AWS needs a moment.

### Step 11 — Check it in AWS Console (optional but cool!)

1. Go to [AWS Console](https://console.aws.amazon.com)
2. Click **EC2** in the search bar
3. Click **"Target Groups"** on the left
4. Click on `secure-ntier-dev-tg`
5. Click the **"Targets"** tab

You should see **2 instances** with status **"healthy"** (green) ✅

---

## 🖥️ PART 6 — Run Locally (No AWS, No Cost!)

Want to test on your own computer first? No AWS needed!

### Step 12 — Start local version

Make sure Docker Desktop is open and running, then type:
```
make local-up
```

Wait about 30 seconds, then open your browser at:
- Frontend: **http://localhost**
- Backend health: **http://localhost:3000/health**

### Step 13 — Stop local version

When you're done:
```
make local-down
```

To also wipe the local database (start completely fresh):
```
make local-reset
```

---

## 💥 PART 7 — Delete Everything (Stop AWS Charges!)

> ⚠️ **IMPORTANT:** AWS charges you by the hour. When you're done testing, **always destroy your setup!**
> Leaving it running costs about **$2–3 per day**.

### Step 14 — Destroy all AWS resources

```
make tf-destroy
```

It will ask you to confirm. Type `yes` and press Enter.

> ⏳ Takes about 5–10 minutes.
>
> ✅ When done you'll see: `Destroy complete! Resources: 28 destroyed.`
>
> 💸 **AWS charges stop immediately!**

---

## 🔄 PART 8 — Update Your App (After Code Changes)

Made changes to your code? Update AWS without rebuilding everything:

```
make push-aws
```

> ⏳ Takes about 5 minutes.
> What it does: builds new Docker images → uploads to AWS → rolls out to servers one by one (zero downtime!)

---

## 🆘 Help! Something Went Wrong

### ❓ Problem: "aws: command not found"
**Fix:** Install AWS CLI from [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), close your terminal, open a new one, try again.

### ❓ Problem: "terraform: command not found"
**Fix:** Install Terraform from [here](https://developer.hashicorp.com/terraform/install), close your terminal, open a new one, try again.

### ❓ Problem: "Error: No valid credential sources found"
**Fix:** Go back to Step 5 and run `aws configure` again. Make sure you paste the keys correctly with no extra spaces.

### ❓ Problem: "Error acquiring the state lock"
**Fix:** A previous deploy got stuck. Type this to unlock:
```
cd terraform
terraform force-unlock LOCK_ID_FROM_ERROR_MESSAGE
```

### ❓ Problem: Health check shows error after deploy
**Fix:** Wait 3 more minutes and try again. New servers take time to boot up. If still broken after 5 minutes:
1. Go to AWS Console → EC2 → Instances
2. Click on one of your instances
3. Click "Connect" → "Session Manager" → "Connect"
4. Type: `tail -100 /var/log/user-data.log`
5. Look for any red error messages

### ❓ Problem: Smoke test keeps failing / timing out
**Fix:** Run the health check manually. Get your ALB URL from Terraform outputs:
```
cd terraform
terraform output app_url
```
Then visit `http://YOUR_URL/health` in your browser.

### ❓ Not sure what's happening?
Check what's running on AWS:
```
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names secure-ntier-dev-asg \
  --query 'AutoScalingGroups[0].Instances[*].HealthStatus'
```
Should say `["Healthy","Healthy"]`

---

## 📋 Quick Reference Cheat Sheet

| What you want to do | Command |
|---|---|
| Check tools installed | `make prereqs` |
| **Full deploy to AWS** | `make deploy-aws` |
| Update app (no terraform) | `make push-aws` |
| Start local version | `make local-up` |
| Stop local version | `make local-down` |
| Wipe local database | `make local-reset` |
| See what terraform will do | `make tf-plan` |
| Apply only terraform changes | `make tf-apply` |
| **💥 Delete everything (stop charges)** | `make tf-destroy` |
| See all available commands | `make help` |

---

## 🗺️ What Was Built on AWS?

When you run `make deploy-aws`, this is what gets created:

```
Your Computer
     │
     ▼
┌─────────────────────────────────────────────────────┐
│                     AWS Cloud                        │
│                                                      │
│  Internet ──► WAF ──► Load Balancer (ALB)           │
│                             │                        │
│              ┌──────────────┴──────────────┐        │
│              ▼                             ▼         │
│         Server 1 🖥️                   Server 2 🖥️   │
│         (EC2 + Docker)             (EC2 + Docker)   │
│              │                             │         │
│              └──────────────┬──────────────┘        │
│                             ▼                        │
│                      Database 🗄️ (RDS PostgreSQL)    │
│                                                      │
│         📦 ECR (stores your Docker images)           │
│         🔐 Secrets Manager (stores passwords)        │
│         📊 CloudWatch (monitors everything)          │
└─────────────────────────────────────────────────────┘
```

> **28 AWS resources** get created automatically from code. No clicking in the AWS Console needed!

---

*Made with ❤️ — If you got stuck, re-read the step carefully and check the Help section above.*

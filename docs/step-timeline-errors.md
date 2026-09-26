# Step-by-Step Timeline — Kab Kya Hoga, Error Aaye To Kya Karna Hai

> Poore deployment ka timeline: har step me **command → kab kya hone wala hai → success output → error aaya to fix**. Hinglish me, beginner friendly.
> Region: `ap-south-1` (Mumbai). Time estimates dev stack (`t3.micro` + `db.t3.micro`) ke hisab se.

**Flow ek nazar me:**

```
Step 1: Tools install (5 min, ek baar)
  → Step 2: aws configure + login check (2 min)
    → Step 3: terraform.tfvars banao (3 min)
      → Step 4: bootstrap-state.sh — S3 + DynamoDB (1 min)
        → Step 5: terraform init (1-2 min)
          → Step 6: terraform plan — 28 resources preview (1 min)
            → Step 7: terraform apply — VPC→ALB→EC2→RDS (10-15 min) ⏳ sabse lamba
              → Step 8: Docker build (3-5 min)
                → Step 9: ECR push (2-3 min)
                  → Step 10: deploy-ec2.sh — SSM + ASG refresh (3-5 min)
                    → Step 11: ALB /health verify (2 min)
                      → Step 12: Update / Redeploy (jab code badlo)
                        → Step 13: terraform destroy — bill rokna (10-12 min)
```

> Detail guides: `DEPLOY_STEPS.md` (English full manual), `docs/instance-guide.md` (kaunsa instance kab), `docs/runbooks/` (instance / database / deployment failure runbooks).

---

## Step 1 — Tools Install Karo (5 min, ek baar)

**Command:**
```bash
git --version && aws --version && terraform -version && docker --version && jq --version
```

**Kab kya hoga:** Har tool apna version print karega. Koi bhi missing hua to uska install karo (Part 1, `DEPLOY_STEPS.md`).

**🟢 Success (aisa dikhega):**
```text
git version 2.40.0
aws-cli/2.15.0
Terraform v1.5.0
Docker version 24.0.0
jq-1.6
```

**🔴 Error 1: `'aws' is not recognized / command not found`**
- **Kyun aaya:** Tool install hua lekin system `PATH` me nahi hai, ya terminal purana khula hai.
- **Fix:** Terminal band karke dobara kholo. Windows par: `sysdm.cpl` → Advanced → Environment Variables → PATH me tool ka folder add karo. Phir version command dobara chalao.

**🔴 Error 2: `Cannot connect to the Docker daemon`**
- **Kyun aaya:** Docker Desktop install hai lekin chal nahi raha.
- **Fix:** Start Menu / Applications se **Docker Desktop kholo**, whale icon green hone tak wait karo, phir `docker ps` chalao (khali list aani chahiye, error nahi).

---

## Step 2 — AWS Login (`aws configure`) (2 min)

**Command:**
```bash
aws configure
# Access Key ID: AKIA... (IAM user terraform-deployer ki)
# Secret Key: .... (csv se copy)
# Default region: ap-south-1
# Output format: json

aws sts get-caller-identity
```

**Kab kya hoga:** `aws configure` keys ko `~/.aws/credentials` me save karega. `get-caller-identity` AWS se wapas tumhara Account ID + ARN layega — matlab laptop ab AWS se baat kar sakta hai.

**🟢 Success:**
```json
{
    "UserId": "AIDAEXAMPLEUSERID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-deployer"
}
```

**🔴 Error 1: `The security token included in the request is invalid (InvalidClientTokenId)`**
- **Kyun aaya:** Access Key me typo hai, ya key IAM me delete/deactivate ho gayi.
- **Fix:** IAM Console → Users → `terraform-deployer` → Security credentials → **Create access key** (nayi), phir `aws configure` dobara chalao.

**🔴 Error 2: `AccessDenied / User is not authorized to perform: ...`**
- **Kyun aaya:** User ke paas permission nahi hai (lab me `AdministratorAccess` chahiye).
- **Fix:** Console → IAM → Users → `terraform-deployer` → Add permissions → `AdministratorAccess` attach karo. Root user se daily kaam mat karo.

**🔴 Error 3: Region galat (`us-east-1` dikh raha)**
- **Kyun aaya:** `aws configure` me region `ap-south-1` nahi likha.
- **Fix:** `aws configure get region` se check karo, galat ho to `aws configure` dobara karke region `ap-south-1` likho.

---

## Step 3 — `terraform.tfvars` Banao (3 min)

**Command:**
```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
# phir file kholo, sirf ye badlo:
# notification_email = "tumhara-real-email@gmail.com"
```

**Kab kya hoga:** Kuch AWS par nahi banega — sirf local config file banegi. Terraform aage isi file se padhega ki kaunsa instance, kitne subnets, kaunsa email.

**🟢 Success:** `ls -l terraform/environments/dev/terraform.tfvars` file dikhaye.

**🔴 Error 1: `notification_email` wahi `you@example.com` reh gaya**
- **Kyun aaya / kya hoga:** Apply to ho jayega lekin SNS alarm emails kabhi nahi milenge.
- **Fix:** File me apna real email likho, phir `terraform apply` (ya `terraform apply -refresh-only` agar infra pehle se live hai).

**🔴 Error 2: `aws_enable_eks = true` galti se kar diya**
- **Kya hoga:** Bill me ~$73/mo control plane + ~$50 nodes extra jud jayega.
- **Fix:** Sikhne ke liye pehle `false` rakho. EKS chahiye tabhi `true` karo (`docs/instance-guide.md` Step 3 dekho).

**🔴 Error 3: `domain_name` me aisi domain likh di jo tumhare paas nahi hai**
- **Kya hoga:** ACM certificate validate nahi hoga, apply atakega.
- **Fix:** Dev me `domain_name = ""` rakho (plain HTTP ALB). Domain tabhi likho jab Route 53 hosted zone tumhare account me ho.

---

## Step 4 — Backend Bootstrap: S3 + DynamoDB (1 min)

**Command:**
```bash
bash terraform/scripts/bootstrap-state.sh ap-south-1
```

**Kab kya hoga:** Terraform ka state (kis resource ka kya ID hai) local file ki jagah **S3 bucket** me save hoga + **DynamoDB table** lock lagayegi taaki do log ek saath apply na karein. Output me bucket + table ka naam dikhega.

**🟢 Success:**
```text
>>> Creating S3 bucket ... in ap-south-1
>>> Enabling versioning ...
>>> Blocking public access ...
>>> Creating DynamoDB table terraform-locks ...
>>> Backend bootstrap complete for ap-south-1
```

**🔴 Error 1: `AccessDenied: s3:CreateBucket`**
- **Kyun aaya:** IAM user me S3/DynamoDB permission nahi.
- **Fix:** Step 2 wala Error 2 dekho — `AdministratorAccess` lagao, script dobara chalao. Script idempotent hai (dobara chalana safe).

**🔴 Error 2: `BucketAlreadyExists / BucketAlreadyOwnedByYou`**
- **Kyun aaya:** Naam ka bucket kisi aur account me hai (global unique hota hai) ya tumhara hi purana hai.
- **Fix:** Agar `...already exists - skipping` likha hai to **normal hai, aage badho**. Agar dusre account ka hai to `backend.hcl` me bucket naam badlo.

---

## Step 5 — `terraform init` (1-2 min)

**Command:**
```bash
cd terraform
terraform init \
  -backend-config="cloud/aws/backend.hcl" \
  -backend-config="key=aws/dev/terraform.tfstate" \
  -backend-config="region=ap-south-1"
```

**Kab kya hoga:** AWS provider plugin download hoga + S3 backend se connection banega. Koi resource **nahi** banega — sirf taiyari.

**🟢 Success:**
```text
Initializing modules...
Initializing the backend...
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

**🔴 Error 1: `Failed to install provider / network unreachable`**
- **Kyun aaya:** Internet slow/blocked, ya proxy.
- **Fix:** Internet check karo, VPN/proxy off karke retry. `terraform init -upgrade` se dobara chalao.

**🔴 Error 2: `Backend initialization failed / NoSuchBucket`**
- **Kyun aaya:** Step 4 skip ho gaya ya galat region/bucket naam.
- **Fix:** Step 4 dobara chalao, phir `backend.hcl` me bucket + region verify karke `init` retry karo.

**🔴 Error 3: `terraform: command not found` yahin par**
- **Fix:** Step 1 Error 1 dekho (PATH / terminal restart).

---

## Step 6 — `terraform plan` — Preview (1 min)

**Command:**
```bash
terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
```

**Kab kya hoga:** Terraform AWS APIs ko **read-only** call karke batayega ki kya banega. Aakhri line sabse important hai — `Plan: 28 to add, 0 to change, 0 to destroy`. Paise **nahi** katega, kuch banega bhi nahi.

**🟢 Success:** `Plan: 28 to add, 0 to change, 0 to destroy` + list me VPC, subnets, NAT, ALB, ASG, RDS, ECR, alarms dikhenge.

**🔴 Error 1: `Error acquiring the state lock: ConditionalCheckFailedException`**
- **Kyun aaya:** Pichli baar `apply` Ctrl+C se roka tha — DynamoDB lock atka reh gaya.
- **Fix:** Error me jo `LOCK_ID` dikha:
  ```bash
  terraform force-unlock <LOCK_ID>
  ```
  Phir `plan` dobara chalao. Lock ID ke bina unlock mat karo.

**🔴 Error 2: `DBSubnetGroupDoesNotCoverEnoughAZs`**
- **Kyun aaya:** `db_subnet_cidrs` dono same AZ me chale gaye.
- **Fix:** `terraform.tfvars` me 2 alag CIDRs rakho (`10.0.21.0/24`, `10.0.22.0/24`), AZs default (pehle 2 available) rehne do.

**🔴 Error 3: `Variable not allowed / Unsupported argument`**
- **Kyun aaya:** `tfvars` me variable ka naam galat likha (jaise `instance_type` ki jagah `aws_instance_type` ya vice versa — example file se copy karo).
- **Fix:** `terraform/environments/dev/terraform.tfvars.example` se naam match karo. `terraform validate` chalake syntax check karo.

---

## Step 7 — `terraform apply` — Asli Deployment (10-15 min) ⏳

**Command:**
```bash
terraform apply -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
# poochhe to: yes
```

**Kab kya hone wala hai (order + time):**
| Time | Kya ban raha hai | Tum kya dekhoge |
|---|---|---|
| 0-2 min | VPC, subnets, IGW, route tables, Security Groups, WAF | `aws_vpc`, `aws_subnet` ... `Creation complete` |
| 2-5 min | NAT Gateway + Elastic IP, ALB, Target Group, ECR repos | NAT `provisioning` → `available` |
| 3-8 min | EC2 Launch Template + ASG (2× `t3.micro` boot, user-data me Docker install) | ASG `Setting desired capacity to 2` |
| 8-14 min | **RDS MySQL** + Secrets Manager secret | RDS `creating` → `available` (sabse slow — **Ctrl+C MAT dabao**) |
| 14-15 min | CloudWatch dashboard + alarms + SNS subscription | `Apply complete! Resources: 28 added` + `app_url`, `registry_url` outputs |

**🟢 Success:**
```text
Apply complete! Resources: 28 added, 0 changed, 0 destroyed.
Outputs:
app_url = "http://secure-ntier-dev-alb-xxx.ap-south-1.elb.amazonaws.com"
registry_url = "123456789012.dkr.ecr.ap-south-1.amazonaws.com"
```
> `app_url` aur `registry_url` note kar lo — agle steps me chahiye. Email me SNS **Confirm subscription** link aayega — click karna mat bhoolo.

**🔴 Error 1: RDS banne me 10 min lage, ghabra ke Ctrl+C daba diya**
- **Kya hoga:** State half-locked, kuch resources bane, kuch nahi.
- **Fix:** Ghabrao mat. Dobara wahi `terraform apply` chalao (Terraform bacha hua kaam continue karega). Agar lock error aaye to Step 6 Error 1 wala `force-unlock`.

**🔴 Error 2: `LimitExceeded / InsufficientInstanceCapacity / VPC limit`**
- **Kyun aaya:** Account me EIP/VPC quota full, ya AZ me `t3.micro` capacity kam.
- **Fix:** Console → EC2 → Limits check karo. Capacity issue ho to thodi der baad retry ya `aws_region` ki AZs badlo. Quota issue ho to AWS Support se limit increase mango.

**🔴 Error 3: `Apply` to success lekin email nahi aaya**
- **Kyun aaya:** SNS subscription pending hai.
- **Fix:** Console → SNS → Topics → `secure-ntier-dev-alerts` → Subscription status `PendingConfirmation` hoga. Email ka spam folder dekho, **Confirm subscription** click karo.

---

## Step 8 — Docker Build (3-5 min)

**Command:**
```bash
cd ..
docker build -t secure-ntier-backend:latest -f docker/backend/Dockerfile .
docker build -t secure-ntier-frontend:latest -f docker/frontend/Dockerfile .
docker images | grep secure-ntier
```

**Kab kya hoga:** Laptop par dono images locally banegi (backend: Node 22 API, frontend: React build → Nginx). Koi AWS kharcha nahi.

**🟢 Success:** `docker images` me dono `latest` dikhenge.

**🔴 Error 1: `Cannot connect to the Docker daemon`**
- **Fix:** Step 1 Error 2 — Docker Desktop start karo, green hone do.

**🔴 Error 2: `npm ci failed / vite build failed`**
- **Kyun aaya:** `application/backend` ya `frontend` me code change tuta hai, ya `node_modules` cache purana.
- **Fix:** Pehle local test: `cd application/backend && npm ci && npm test`. Frontend: `npm ci && npm run build`. Jo error aaye use fix karo, phir `docker build --no-cache` se dobara banao. CI log (`Jenkinsfile-ci`) me bhi wahi stage fail hoga — wahi fix kaam ayega.

---

## Step 9 — ECR Push (2-3 min)

**Command:**
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-south-1"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

docker tag secure-ntier-backend:latest  "${REGISTRY}/secure-ntier-dev-backend:latest"
docker tag secure-ntier-frontend:latest "${REGISTRY}/secure-ntier-dev-frontend:latest"

docker push "${REGISTRY}/secure-ntier-dev-backend:latest"
docker push "${REGISTRY}/secure-ntier-dev-frontend:latest"
```

**Kab kya hoga:** Docker ECR me login karega (`Login Succeeded`), phir dono images private registry me upload hongi. EC2 aage inhi ko pull karega.

**🟢 Success:** `Login Succeeded` + push ke baad `latest: digest: sha256:... size: ...` lines.

**🔴 Error 1: `no basic auth credentials` on `docker push`**
- **Kyun aaya:** ECR token 12 ghante me expire hota hai.
- **Fix:** Upar wali `docker login` line dobara chalao, phir `push` retry.

**🔴 Error 2: `RepositoryNotFoundException / AccessDenied on push`**
- **Kyun aaya:** Repo naam galat (`secure-ntier-dev-backend` exact chahiye) ya IAM me ECR push permission nahi.
- **Fix:** `aws ecr describe-repositories --region ap-south-1` se naam verify karo. Permission ke liye Step 2 Error 2 dekho.

---

## Step 10 — Deploy: SSM + ASG Instance Refresh (3-5 min)

**Command:**
```bash
bash cicd/scripts/deploy-ec2.sh latest ap-south-1 dev secure-ntier

# progress dekho:
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name secure-ntier-dev-asg \
  --region ap-south-1 \
  --query "InstanceRefreshes[0].{Status:Status,Percentage:PercentageComplete}"
```

**Kab kya hone wala hai:**
1. Script SSM Parameter (`/secure-ntier/dev/backend-image`, `/frontend-image`) ko naye ECR URI par point karega.
2. ASG **rolling refresh** start karega — ek-ek karke purane EC2 ko naya launch karega.
3. Naya EC2 boot hoke `user-data.sh` chalata hai: IAM role se ECR login → Secrets Manager se DB password → SSM se image URI → `docker compose` up.
4. Status `InProgress (0% → 50% → 100%)` → `Successful` (~3-5 min).

**🟢 Success:**
```text
>>> /secure-ntier/dev/backend-image = 123456.../secure-ntier-dev-backend:latest
>>> Instance refresh started on secure-ntier-dev-asg
# phir: Status: Successful, PercentageComplete: 100
```

**🔴 Error 1: Refresh `InProgress` par atka / `Failed`**
- **Kyun aaya:** Naya instance `/health` pass nahi kar raha (image kharab, DB secret galat, ECR pull fail).
- **Fix (order me):**
  ```bash
  # 1. Target health dekho
  TG_ARN=$(aws elbv2 describe-target-groups --names secure-ntier-dev-tg --region ap-south-1 --query "TargetGroups[0].TargetGroupArn" --output text)
  aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region ap-south-1
  # 2. Boot log SSM se (bina SSH):
  INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names secure-ntier-dev-asg --region ap-south-1 --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text)
  aws ssm send-command --instance-ids "$INSTANCE_ID" --document-name "AWS-RunShellScript" --parameters 'commands=["tail -n 50 /var/log/user-data.log", "docker ps"]' --region ap-south-1
  ```
  Log me `ImageNotFound` → Step 9 dobara karo. `ECONNREFUSED db` → `docs/runbooks/database-failure.md` dekho. Phir purane good image par rollback: `docs/runbooks/rollback.md`.

**🔴 Error 2: `SSM parameter not found / AccessDenied`**
- **Kyun aaya:** Env naam galat (`dev` vs `prod`) ya IAM me SSM permission nahi.
- **Fix:** `aws ssm get-parameter --name "/secure-ntier/dev/backend-image" --region ap-south-1` se check karo. Naam exact hona chahiye.

---

## Step 11 — Verify: ALB + `/health` (2 min)

**Command:**
```bash
ALB_URL=$(cd terraform && terraform output -raw app_url)
echo "$ALB_URL"
curl -s "$ALB_URL/health" | jq .
bash scripts/health-check.sh "$ALB_URL"
```

**Kab kya hoga:** Browser me React UI khulega. `/health` JSON me `"db":"connected"` aana chahiye — matlab ALB → EC2 → RDS poori chain live hai.

**🟢 Success:**
```json
{ "status": "ok", "db": "connected", "uptime": 124.5 }
```
```text
RESULT: PASS (backend reachable, database connected)
```

**🔴 Error 1: `502 Bad Gateway`**
- **Kyun aaya:** ALB sahi hai, EC2 port 80 par jawab nahi de raha (container down ya image missing).
- **Fix:** Step 10 Error 1 wale 2 commands chalao (target-health + user-data log). Usually SSM image parameter `pending` hai = Step 10 dobara chalao.

**🔴 Error 2: `503 Service Unavailable`**
- **Kyun aaya:** Koi healthy target hi nahi — ASG me 0 instances (`asg_desired_capacity=0`?) ya sab unhealthy.
- **Fix:** `terraform.tfvars` me `asg_desired_capacity = 2` karo + `terraform apply`. Phir Step 10 ka refresh.

**🔴 Error 3: `/health` me `"db":"disconnected"`**
- **Kyun aaya:** Backend chalu hai lekin RDS se baat nahi ho rahi (SG, secret host, ya RDS down).
- **Fix:** `docs/runbooks/database-failure.md` → Case 1 (SG 3306 + secret host check). RDS status: `aws rds describe-db-instances --db-instance-identifier secure-ntier-dev-db --region ap-south-1 --query 'DBInstances[0].DBInstanceStatus'` → `available` hona chahiye.

---

## Step 12 — Code Badla? Zero-Downtime Redeploy (5 min)

**Kab kya hoga:** Nayi image tag (`v2`) ECR me jayegi, SSM us par point karega, ASG ek-ek instance replace karega — **site down nahi hogi** (`MinHealthyPercentage:50`).

**Command:**
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"

docker build -t "${REGISTRY}/secure-ntier-dev-frontend:v2" -f docker/frontend/Dockerfile .
docker push "${REGISTRY}/secure-ntier-dev-frontend:v2"

aws ssm put-parameter --name "/secure-ntier/dev/frontend-image" \
  --value "${REGISTRY}/secure-ntier-dev-frontend:v2" \
  --type String --overwrite --region ap-south-1

aws autoscaling start-instance-refresh \
  --auto-scaling-group-name secure-ntier-dev-asg --region ap-south-1 \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":120}'
```

**🔴 Error: Naya version toot gaya, site red ho gayi**
- **Fix — Rollback (2 min):** Ghabrao mat, purana tag wapas point karo:
  ```bash
  aws ssm put-parameter --name "/secure-ntier/dev/frontend-image" \
    --value "${REGISTRY}/secure-ntier-dev-frontend:latest" \
    --type String --overwrite --region ap-south-1
  aws autoscaling start-instance-refresh \
    --auto-scaling-group-name secure-ntier-dev-asg --region ap-south-1
  ```
  Detail: `docs/runbooks/rollback.md` + `docs/runbooks/deployment-failure.md`.

---

## Step 13 — Kaam Khatam? `terraform destroy` — Bill Roko (10-12 min)

**Command:**
```bash
cd terraform
terraform destroy -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"
# poochhe to: yes
```

**Kab kya hoga:** RDS (~5 min) → NAT + ALB + EC2 → VPC — sab delete hoga. Aakhri line `Destroy complete! Resources: 28 destroyed.` Bill **usi second** ruk jayega (pehle ka accrued bill rahega — billing me 24h delay normal hai).

**🟢 Success:** `Destroy complete! Resources: 28 destroyed.` + Console me EC2=0, RDS=0, NAT=0.

**🔴 Error 1: `deletion_protection enabled / snapshot required`**
- **Kyun aaya:** Prod me `deletion_protection=true` hai (janbujh ke, taaki DB galti se na ude).
- **Fix:** Dev me ye `false` + `skip_final_snapshot=true` rakho. Prod destroy karna hi hai to pehle tfvars me `deletion_protection=false`, `skip_final_snapshot=false` karke `apply`, phir `destroy`.

**🔴 Error 2: Destroy ke baad bhi bill aa raha hai**
- **Kyun aaya:** Log groups, S3 state bucket, ECR images Terraform ke bahar reh gaye.
- **Fix:**
  ```bash
  bash scripts/cleanup.sh ap-south-1 secure-ntier dev
  ```
  + Console me CloudWatch Log Groups, S3 (`*-cloudtrail`, `*-alb-logs`), ECR images manually verify karo (`docs/cost-guide.md` §6 checklist).

---

## Quick Error Finder (Ctrl+F karo)

| Error string | Step | Fix ek line me |
|---|---|---|
| `command not found / not recognized` | 1, 5 | PATH + terminal restart |
| `Cannot connect to the Docker daemon` | 1, 8 | Docker Desktop start karo |
| `InvalidClientTokenId` | 2 | Nayi access key + `aws configure` |
| `not authorized / AccessDenied` | 2, 4, 9 | `AdministratorAccess` lagao |
| `state lock / ConditionalCheckFailed` | 6 | `terraform force-unlock <LOCK_ID>` |
| `DBSubnetGroupDoesNotCoverEnoughAZs` | 6 | 2 alag DB CIDRs rakho |
| `LimitExceeded / InsufficientCapacity` | 7 | Limits check + retry |
| `npm ci / vite build failed` | 8 | Local `npm test/build` fix, phir rebuild |
| `no basic auth credentials` | 9 | `docker login` dobara (12h expiry) |
| `RepositoryNotFound` | 9 | Repo naam exact likho |
| Refresh `Failed / stuck` | 10 | target-health + user-data log dekho |
| `502 Bad Gateway` | 11 | Container down — Step 10 check karo |
| `503 Service Unavailable` | 11 | `desired_capacity=2` + apply |
| `"db":"disconnected"` | 11 | `runbooks/database-failure.md` Case 1 |
| Destroy blocked (protection) | 13 | `deletion_protection=false` karke apply phir destroy |
| Bill ruk nahi raha | 13 | `scripts/cleanup.sh` + manual S3/logs/ECR check |


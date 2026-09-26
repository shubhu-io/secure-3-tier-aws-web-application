# EC2 / RDS Instance Selection Guide — Kaunsa Instance Kis Liye Best Hai

> Is project (`secure-ntier-cloud-platform`, region `ap-south-1` Mumbai) me 4 jagah instance type select hota hai: **App EC2 (ASG)**, **RDS Database**, **EKS Nodes**, **Jenkins Controller**. Ye guide step-by-step full detailing me batata hai kaunsa instance kab lena hai, kyun lena hai, kitna cost aayega, aur Terraform me kaise change karna hai.

---

## Step 0 — Basic Concept (2 min me samjho)

Har instance type ka naam aise padho: `t3.micro`, `db.t3.medium`, `m5.large`

| Part | Matlab | Example |
|---|---|---|
| **Family letter** (`T`, `M`, `C`, `R`) | Kis kaam ke liye optimized hai | `T`=Burstable/general, `M`=Balanced, `C`=CPU, `R`=Memory |
| **Generation** (`3`, `5`, `6g`) | Naya = fast + sasta. `g` = Graviton ARM (20% sasta, lekin image ARM compatible hona chahiye) | `t3` < `t4g` (ARM) |
| **Size** (`micro`, `small`, `medium`, `large`, `xlarge`) | vCPU + RAM double hota jata hai | `micro`=2vCPU/1GB, `medium`=2vCPU/4GB, `large`=2vCPU/8GB |
| **`db.` prefix** | RDS database instance hai (EC2 nahi) | `db.t3.micro` |

**Burstable (T3/T4g) vs Fixed (M5/C5/R5):**
- **T3/T4g = Burstable** — Normal time me kam CPU use karo, burst me 100% tak jao (CPU credits se). Dev, low-traffic web app, Jenkins (idle) ke liye **best + sabse sasta**. Agar CPU 24x7 70%+ rahega to credits khatam → throttling → tab M5/C5 lo.
- **M5/C5/R5 = Fixed** — Hamesha full performance. Prod heavy API, background workers, high-traffic ke liye.

**Thumb rule:**
```
CPU mostly < 40% rehta hai  →  T3 / T4g (burstable) lo
CPU hamesha 60-80% rehta hai →  M5 / C5 (fixed) lo
RAM full ho rahi hai (OOM)   →  R5 / M5 (memory) lo, T3 mat badao
```

---

## Step 1 — App Tier: EC2 Auto Scaling Group (Frontend + Backend Docker)

**File:** `terraform/cloud/aws/modules/compute/main.tf` → `var.instance_type`
**Variable:** `terraform/cloud/aws/variables.tf` → `instance_type` (default `t3.micro`)

Ye instances private app subnets me Docker Compose chalate hain (React Nginx:80 + Node API:3000). Har instance ~0.6GB RAM khata hai idle par.

### 1A. Detail Comparison Table (ap-south-1 On-Demand approx)

| Instance | vCPU / RAM | Network | ~Cost/mo (1 node) | Kis liye BEST hai | Kab MAT lo |
|---|---|---|---|---|---|
| **`t3.micro`** ⭐ Dev default | 2 / 1 GB | up to 5 Gbps | **~$7.5** | **Learning, dev, demo, interview.** Free-tier (750 hrs). 1-50 concurrent users. Isi repo ka dev default. | Prod, 1GB me 2 containers + logs tight padenge load par |
| **`t3.small`** | 2 / 2 GB | up to 5 Gbps | ~$15 | Small staging, 50-200 users, jab `t3.micro` me OOM / CPU credit exhaust ho | 24x7 high CPU (>60%) |
| **`t3.medium`** ⭐ Prod default | 2 / 4 GB | up to 5 Gbps | **~$30** | **Small prod (prod.tfvars.example default).** 200-1000 users, dono containers + CloudWatch agent aaram se. Jenkins bhi isi par chalta hai. | Sustained CPU >70% (tab `m5.large` lo) |
| **`t3.large`** | 2 / 8 GB | up to 5 Gbps | ~$60 | Medium prod, 1000-5000 users, ya jab ek hi box par EKS-style extra agents ho | Paise bachane ho to pehle ASG `max_size` badao, instance mat badao |
| **`m5.large`** | 2 / 8 GB | up to 10 Gbps | ~$70 | **Heavy prod, fixed performance.** CPU 24x7 high, no throttling chahiye, latency-sensitive API | Dev (overkill, 10x cost vs free-tier micro) |
| **`c5.large`** | 2 / 4 GB | up to 10 Gbps | ~$62 | CPU-intensive API (bcrypt, JWT verify, image resize). RAM kam chahiye, CPU zyada | Memory-hungry app (Node heap bada hai to OOM hoga) |
| **`t4g.micro` / `t4g.medium`** (ARM) | same + 20% sasta | up to 5 Gbps | ~$6 / ~$24 | **Sabse sasta prod** — lekin Docker images ARM (`linux/arm64`) rebuild karne padenge. `node:22-alpine` ARM support karta hai, test karke lo | Jaldi deploy karna ho, multi-arch build nahi aata ho |

### 1B. Kaise decide karo (3 checks)

1. **CloudWatch `CPUUtilization` dekho (ASG avg):** 2 hafte <40% → same raho. Bar-bar >70% aur scaling ho rahi hai → ek size up karo.
2. **`docker stats` / OOM kills dekho:** `dmesg | grep -i oom` me entry = RAM kam → `small→medium` (RAM double).
3. **CPU Credits (`CPUCreditBalance`):** Zero ho raha hai T3 par → workload burstable nahi hai → `m5.large` par shift karo.

### 1C. Is project me kaise change karein

```hcl
# terraform/environments/dev/terraform.tfvars
instance_type        = "t3.micro"    # dev: sasta
asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4
```
```hcl
# terraform/environments/prod/terraform.tfvars
instance_type        = "t3.medium"   # prod: headroom
asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 6             # pehle scale-out badao, phir instance size
```

> **Golden rule:** Pehle **ASG max_size badao (horizontal scale)**, phir instance type badao (vertical scale). 2× `t3.medium` hamesha 1× `t3.large` se zyada reliable (AZ failure survive karta hai).

---

## Step 2 — Database Tier: RDS MySQL 16

**File:** `terraform/cloud/aws/modules/database/main.tf` → `var.db_instance_class`
**Variable:** `db_instance_class` (default `db.t3.micro`), `db_multi_az`, `db_allocated_storage`

DB private isolated subnets me hai, sirf App SG se port 3306 par reachable. DB ko **kabhi burstable se bada bina soch-samjhe mat karo** — storage + backup cost bhi judta hai.

### 2A. Detail Comparison Table

| Instance | vCPU / RAM | ~Cost/mo + 20GB gp3 | Kis liye BEST hai | Kab MAT lo |
|---|---|---|---|---|
| **`db.t3.micro`** ⭐ Dev default | 2 / 1 GB | **~$13 + $2 storage** | **Dev, learning, demo.** 10-50 connections, test data <5GB. Single-AZ (`db_multi_az=false`). | Prod (failover nahi, burst exhaust par API slow) |
| **`db.t3.small`** | 2 / 2 GB | ~$26 + storage | Staging, 50-200 connections, small prod trial | 24x7 heavy writes |
| **`db.t3.medium`** ⭐ Prod default | 2 / 4 GB | **~$52 + storage** | **Small prod (prod.tfvars.example default).** 200-500 connections + `db_multi_az=true` (standby replica, RPO≈0, failover <60s). | >500 connections / >100GB data (tab `db.m5.large`) |
| **`db.m5.large`** | 2 / 8 GB | ~$110 + storage | Medium prod, reporting queries, 500-2000 connections, fixed performance | Dev (8x cost) |
| **`db.r5.large`** | 2 / 16 GB | ~$140 + storage | Memory-heavy: bada `shared_buffers`, complex JOINs, analytics on same DB | Normal CRUD app (paise waste) |
| **`db.t4g.micro/medium`** (ARM) | same, ~20% sasta | ~$10 / ~$42 | Sasta prod — mysql 16 Graviton support karta hai, koi app change nahi chahiye | Agar `enhanced_monitoring` purane tool se check karte ho (test kar lo) |

### 2B. Storage + HA ke saath faisla

```hcl
# DEV (sasta, disposable)
db_instance_class    = "db.t3.micro"
db_multi_az          = false          # standby ka ~2x cost bachta hai
db_allocated_storage = 20             # gp3, auto-grow max_allocated_storage tak
backup_retention_days = 7
deletion_protection   = false
skip_final_snapshot   = true

# PROD (reliable)
db_instance_class    = "db.t3.medium"
db_multi_az          = true           # sync standby, AZ fail survive
db_allocated_storage = 50
backup_retention_days = 30            # compliance ke liye 14-35
deletion_protection   = true
skip_final_snapshot   = false         # destroy se pehle final snapshot
```

**3 DB checks:**
1. **RDS `DatabaseConnections` + `FreeableMemory`:** Memory <200MB bache → ek size up.
2. **`ReadLatency` / `WriteLatency` >20ms sustained:** gp3 IOPS kam → pehle storage badao, phir instance.
3. **Prod me `Multi-AZ` hamesha ON** — instance bada karne se pehle HA on karo, wahi asli reliability deta hai.

---

## Step 3 — EKS Nodes (Optional Kubernetes)

**Enable:** `enable_eks = true` (default `false` — control plane hi ~$73/mo!)
**Variable:** `eks_node_instance_types` (default `["t3.medium"]`), `eks_node_min/desired/max_size`

EKS node group private app subnets me chalta hai. Har pod ~0.3-0.5GB leta hai (frontend+backend+metrics-server).

| Instance | vCPU / RAM | ~Cost (2 nodes) | Kis liye BEST hai |
|---|---|---|---|
| **`t3.medium`** ⭐ default | 2 / 4 GB | ~$60 + $73 control plane | **Learning EKS, small workload (10-20 pods).** Default isiliye hai. |
| **`t3.large`** | 2 / 8 GB | ~$120 + $73 | 20-50 pods, Prometheus/Grafana bhi cluster me chalana ho |
| **`m5.large`** | 2 / 8 GB fixed | ~$140 + $73 | Prod EKS, HPA ke saath stable performance, no credit worry |
| **`t3.small`** (NOT recommended) | 2 / 2 GB | ~$30 + $73 | Bilkul mat lo — kubelet + CNI + 2 app pods me hi RAM full, `Evicted` pods milenge |

```hcl
# EKS chahiye to:
enable_eks              = true
eks_node_instance_types = ["t3.medium"]  # start yahi se
eks_node_min_size       = 2
eks_node_desired_size   = 2
eks_node_max_size       = 4
```

> EKS sikhna hai to pehle `enable_eks=false` par EC2+ASG wala flow master karo (sasta), phir EKS on karo. Dono ek saath chalane = ~$220+/mo.

---

## Step 4 — Jenkins Controller (Optional CI/CD)

**Enable:** `enable_jenkins = true` (default `false` — Jenkins free hai, Jenkins ~$15-25/mo)
**Variable:** `jenkins_instance_type` (default `t3.medium`)

Jenkins controller par Java + Docker builds + `kubectl` chalta hai — **1GB RAM me Jenkins OOM ho jata hai**, isiliye default `t3.medium` hai, `micro` mat karo.

| Instance | vCPU / RAM | ~Cost/mo | Kis liye BEST hai |
|---|---|---|---|
| **`t3.medium`** ⭐ default | 2 / 4 GB | ~$30 (30GB gp3 sahit ~$15-25 effective burst) | **Single team, 5-10 builds/day.** Minimum sane size for Jenkins. |
| **`t3.large`** | 2 / 8 GB | ~$60 | Parallel pipelines (3-5 concurrent builds), Docker layer cache bada |
| **`t3.micro/small`** | 2 / 1-2 GB | ~$7-15 | **MAT LO** — Jenkins boot hi nahi hoga / build ke time freeze |

```hcl
enable_jenkins       = true
jenkins_instance_type = "t3.medium"   # micro mat karna
# jenkins_ingress_cidrs = ["1.2.3.4/32"]  # apna IP likho, 0.0.0.0/0 mat rakho
```

> **Ek CI engine rule:** Jenkins (managed, free) **YA** Jenkins (self-hosted) — dono mat chalao. Course/demo ke liye Actions kaafi hai.

---

## Step 5 — Final Recommendation Matrix (Copy-Paste Ready)

| Scenario | App EC2 | RDS | EKS nodes | Jenkins | ~Total/mo |
|---|---|---|---|---|---|
| **A. Free learning (local)** | — (Docker Compose) | — (local mysql) | — | — | **$0** |
| **B. Cheapest real AWS (single-AZ dev)** | `t3.micro` ×1 | `db.t3.micro` single-AZ | off | off | **~$45-60** |
| **C. Default dev (repo default, Multi-AZ app)** | `t3.micro` ×2 | `db.t3.micro` single-AZ | off | off | **~$95-140** |
| **D. Small prod (prod.tfvars.example)** | `t3.medium` ×2-6 | `db.t3.medium` Multi-AZ | off | off | **~$200-350** |
| **E. Prod + Kubernetes lab** | `t3.micro` ×2 + `t3.medium` EKS ×2 | `db.t3.small` | `t3.medium` | off | **~$220-300** |
| **F. Heavy prod (1000+ users)** | `m5.large` ×3-6 | `db.m5.large` Multi-AZ | `m5.large` | off (Actions) | **~$450-700** |

### Apply karne ke steps

```bash
# 1. tfvars copy + edit karo
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
# nano/vim me instance_type, db_instance_class set karo (upar ki table se)

# 2. Plan me cost impact dekho
cd terraform
terraform plan -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"

# 3. Apply (ASG rolling refresh khud ho jayega, RDS me thoda downtime ho sakta hai)
terraform apply -var="cloud=aws" -var-file="environments/dev/terraform.tfvars"

# 4. Verify
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].LaunchTemplate"
aws rds describe-db-instances --query "DBInstances[].DBInstanceClass"
```

**Monitoring ke baad tune karo:** CloudWatch me `ASGAverageCPUUtilization`, `CPUCreditBalance`, `FreeableMemory`, `DatabaseConnections` alarms already repo me hain (`modules/monitoring`) — 2 hafte data dekh ke hi size final karo, pehle din bada instance mat lo.


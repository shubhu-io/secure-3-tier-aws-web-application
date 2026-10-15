# Architecture Diagrams

All platform diagrams are crisp, high-resolution **Full HD (1920x1080) PNG images** located directly in this directory (`diagrams/*.png`) and embedded throughout the project documentation and main [`README.md`](../README.md) so they display instantly on GitHub without any external rendering tools or CLI dependencies required.

All diagrams are standardized to showcase **AWS Region `ap-south-1` (Mumbai)**.

---

## 🗺️ Diagram Gallery

| # | Architecture Diagram | Image File | Description |
|---|----------------------|------------|-------------|
| **1** | **Overall Architecture (Big Picture)** | [**`architecture.png`**](./architecture.png) | Master architectural blueprint: User ➔ Route 53 ➔ WAF ➔ ALB ➔ EC2 ASG ➔ RDS Multi-AZ, plus supporting services. |
| **2** | **VPC Network Architecture** | [**`network.png`**](./network.png) | Multi-AZ VPC (10.0.0.0/16), 6 subnets across 2 AZs, Route Tables, Internet Gateway & NAT Gateway. |
| **3** | **Security Architecture** | [**`security.png`**](./security.png) | 5-layer Defence-in-Depth (Perimeter, Network, Application, Data, Identity) & Continuous Auditing. |
| **4** | **CI/CD Pipeline Flow** | [**`cicd.png`**](./cicd.png) | 8 sequential stages from git push to Trivy vulnerability scan, ECR push, and live deployment. |
| **5** | **User Request Flow** | [**`request-flow.png`**](./request-flow.png) | Step-by-step traffic and data path: Client ➔ WAF ➔ ALB ➔ React ➔ Node API ➔ MySQL. |
| **6** | **Deployment Lifecycle & Rollback** | [**`deployment-flow.png`**](./deployment-flow.png) | Complete deployment lifecycle with automated health verification and zero-downtime rollback. |
| **7** | **Failure Auto-Recovery** | [**`failure-flow.png`**](./failure-flow.png) | Self-healing sequence when an EC2 instance dies; ALB traffic isolation and ASG replacement. |
| **8** | **Disaster Recovery & Multi-AZ** | [**`disaster-recovery.png`**](./disaster-recovery.png) | Multi-AZ synchronous replication, automated RDS snapshots, and RTO/RPO target metrics. |
| **9** | **Kubernetes (AWS EKS) Architecture** | [**`kubernetes.png`**](./kubernetes.png) | AWS EKS cluster, Ingress ALB controller, Worker Nodes, Pods, HPA, and native cloud integrations. |
| **10**| **Technology Stack** | [**`stack.png`**](./stack.png) | Decoupled 3-tier specification across Presentation, Application, Database, and DevOps tiers. |
| **11**| **Observability Architecture (NEW)** | [**`observability.mmd`**](./observability.mmd) | Replaces CloudWatch-only view: Prometheus + Grafana + Loki + Blackbox overlay + SNS fan-out. GitHub-rendered Mermaid. |

---

## 🖼️ Embedded Previews

### 1. Overall Architecture (Big Picture)
![Overall Architecture](./architecture.png)

---

### 2. Full Deployment Lifecycle & Rollback Flow
![Deployment Flow](./deployment-flow.png)

---

### 3. VPC Network Architecture
![VPC Network Architecture](./network.png)

---

### 4. Security Architecture (Defence in Depth)
![Security Architecture](./security.png)

---

### 5. CI/CD Pipeline Automation
![CI/CD Pipeline](./cicd.png)

---

### 6. EC2 Failure Auto-Recovery Sequence
![Failure Recovery](./failure-flow.png)

---

### 7. Disaster Recovery & Multi-AZ Architecture
![Disaster Recovery](./disaster-recovery.png)

---

### 8. Kubernetes (AWS EKS) Architecture
![Kubernetes EKS](./kubernetes.png)

---

### 9. 3-Tier Technology Stack
![Technology Stack](./stack.png)

---

### 10. End-to-End User Request Flow
![User Request Flow](./request-flow.png)

---

### 11. Observability Architecture (NEW — replaces CloudWatch-only)
```mermaid
flowchart TB
    Users --> R53[Route 53 DNS]
    R53 --> WAF[AWS WAF v2]
    WAF --> ALB[ALB public subnets]
    ALB --> ASG1[ASG AZ-a: EC2 + Docker]
    ALB --> ASG2[ASG AZ-b: EC2 + Docker]
    ASG1 --> RDS[(RDS MySQL Multi-AZ)]
    ASG2 --> RDS
    ALB --> CW[CloudWatch Metrics -> Alarms -> SNS -> Email]
    ASG1 -. /metrics .-> PROM[Prometheus :9090]
    ASG2 -. /metrics .-> PROM
    BB[Blackbox /health] --> PROM
    PROM --> GRAF[Grafana :3001]
    PT[Promtail] --> LOKI[Loki :3100]
    LOKI --> GRAF
    GRAF --> SNS
```
Full source: [`observability.mmd`](./observability.mmd). Configs in `../monitoring/` + `../docker/docker-compose.monitoring.yml`.

---

## 📌 Accuracy Guarantee

- Every diagram strictly matches the Terraform code in [`terraform/cloud/aws/`](../terraform/cloud/aws/).
- If you modify CIDR blocks, subnet layouts, security groups, or deployment steps, update the corresponding diagram assets to keep the documentation synchronized.
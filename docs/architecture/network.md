# Network Architecture

## What is a VPC?

A **Virtual Private Cloud** is your own logically isolated network inside AWS.
You define its IP range (CIDR), subnets, routing, and internet access. Think
of it as a building: the VPC is the site, subnets are the floors, route
tables are the elevators/stairwells, and security groups are the doors.

## IP planning

The platform uses one VPC with a **/16** block and three tiers of subnets
(**/24** each) across **two availability zones**:

```text
VPC           10.0.0.0/16

Public-A      10.0.1.0/24     ALB + NAT Gateway          (AZ a)
Public-B      10.0.2.0/24     ALB (spare capacity)        (AZ b)

App-A         10.0.11.0/24    EC2 instances               (AZ a)
App-B         10.0.12.0/24    EC2 instances               (AZ b)

DB-A          10.0.21.0/24    RDS primary                 (AZ a)
DB-B          10.0.22.0/24    RDS standby / multi-AZ      (AZ b)
```

### Why these numbers?

CIDR math: a `/24` has 256 addresses (254 usable). A `/16` has 65,536.
Splitting `10.0.0.0/16` into `/24` tiers leaves room to grow and keeps tiers
recognizable by their third octet:

```text
10.0. 1.0/24   →  public tier   (1)
10.0. 2.0/24   →  public tier   (2)
10.0.11.0/24   →  app tier      (11)
10.0.12.0/24   →  app tier      (12)
10.0.21.0/24   →  db tier       (21)
10.0.22.0/24   →  db tier       (22)
```

The pattern (`1x` app, `2x` db) makes subnet purposes obvious in logs and
dashboards. **Do not use the default VPC** — it has no private subnets and
every resource gets a public IP, which is exactly what we are avoiding.

## Subnet types

| Type | Public IP? | Route 0.0.0.0/0 via | Contains |
| ---- | ---------- | ------------------- | -------- |
| Public | yes | Internet Gateway | ALB, NAT |
| App (private) | no | NAT Gateway | EC2 |
| DB (private) | no | *(none)* | RDS |

## Diagram

![VPC Network Architecture](../../diagrams/network.png)

## Routing

| Route table | Routes |
| ----------- | ------ |
| Public | `10.0.0.0/16 → local`, `0.0.0.0/0 → Internet Gateway` |
| App | `10.0.0.0/16 → local`, `0.0.0.0/0 → NAT Gateway` |
| DB | `10.0.0.0/16 → local` **(no default route)** |

The DB route table has **no** default route: even if someone opened a
security group to the internet, the packets would have nowhere to go. This is
defense in depth — routing and firewalls must *both* be wrong before RDS is
reachable from outside.

## NAT Gateway

Instances in private subnets still need the internet for: pulling Docker
images, Ubuntu patches, and outbound API calls. The NAT Gateway provides this
**one-way door**: outbound connections pass through, but nothing from the
internet can initiate a connection back to the private instance.

- **Dev:** 1 NAT Gateway (cheaper).
- **Prod:** 2 (one per AZ) so an AZ failure doesn't cut outbound connectivity.

> ⚠️ NAT Gateway is one of the most expensive components (~$32/month each).
> See the [cost guide](../cost-guide.md).

## Network ACLs (NACLs)

Security groups are **stateful** (return traffic allowed automatically) and
apply per-instance. NACLs are **stateless** and apply per-subnet — a second
firewall layer that keeps working even if a security group is misconfigured.

| NACL | Key inbound rules | Outbound |
| ---- | ----------------- | -------- |
| Public | 80, 443 from anywhere; ephemeral return traffic | all |
| App | 80 from public subnets (ALB); ephemeral VPC traffic | all |
| DB | 5432 from app subnets only; ephemeral VPC | ephemeral |

Because NACLs are stateless, each rule must be paired with its return-traffic
counterpart (ephemeral ports 1024–65535).

## VPC Flow Logs

Captures every accepted/rejected packet at the ENI level into CloudWatch Logs.
Critical for:

- Security investigations (who tried to reach the DB?).
- Network troubleshooting (is traffic actually reaching the app?).
- Cost/performance analysis.

## Verification

```bash
# subnets and their tier tags
aws ec2 describe-subnets --region <region> \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Subnets[].{Id:SubnetId,Cidr:CidrBlock,Tags:Tags[?Key==`Tier`].Value}'

# routes on the DB route table (should have NO 0.0.0.0/0)
aws ec2 describe-route-tables --region <region> \
  --filters "Name=tag:Tier,Values=db" \
  --query 'RouteTables[].Routes'
```

## Cloud mapping

The same /16 + /24 tier layout is provisioned by every cloud module
(`terraform/cloud/<cloud>/modules/vpc`). The concepts translate as:

| Concept | AWS | Azure | GCP |
| ------- | --- | ----- | --- |
| Virtual network | VPC | VNet | VPC network |
| Tiers | public/app/db subnets + route tables | subnets + route tables | subnets + routes |
| Internet edge | Internet Gateway | default system route to the internet (no IGW object) | default internet gateway on the VPC |
| Outbound-only egress | NAT Gateway | NAT Gateway | Cloud NAT |
| Stateless/per-tier firewall | Network ACLs | Network Security Groups | VPC firewall rules |
| Network audit | VPC Flow Logs | NSG flow logs | VPC Flow Logs |

> Note: Azure NSGs and GCP firewall rules are **stateful**, unlike AWS NACLs —
> the layered-firewall idea carries over, not the statelessness detail.

## Key takeaway

Network isolation comes from **three independent mechanisms**: subnet routing
(no route = no path), NACLs (stateless subnet firewall), and security groups
(stateful instance firewall). Any one of them alone could be a misconfiguration
away from an exposure; together they make a public database practically
impossible.

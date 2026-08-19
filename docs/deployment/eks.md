# Deploying to Kubernetes (EKS)

This guide provisions the EKS cluster with Terraform and deploys the
application to it. It's an **optional** add-on that coexists with the EC2 +
Docker Compose path.

> ⚠️ **COST WARNING**: EKS control plane + a 2×`t3.medium` node group is the
> most expensive option in this project (roughly +$100–150/month on top of the
> EC2 stack). Only enable it when you actually need Kubernetes, and always
> `terraform destroy` when done.

## 1. Enable EKS in Terraform

In your environment file (e.g. `terraform/environments/dev/terraform.tfvars`):

```hcl
enable_eks          = true
eks_ci_iam_arn      = "arn:aws:iam::<ACCOUNT>:user/github-actions-cicd"   # optional
```

Optional knobs (defaults are fine):

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `eks_cluster_version` | `1.31` | Kubernetes version |
| `eks_node_instance_types` | `["t3.medium"]` | Node instance types |
| `eks_node_min_size` / `eks_node_desired_size` / `eks_node_max_size` | 2 / 2 / 4 | Node group size |
| `eks_ci_iam_arn` | `""` | IAM principal granted cluster admin for CI/CD `kubectl` |

Then apply:

```bash
cd terraform
terraform init -backend-config="environments/dev/backend.hcl"
terraform plan -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan
terraform apply plan.tfplan
```

Expected output includes `eks_cluster_name`, `eks_cluster_endpoint`, and
`eks_connect_command`.

## 2. Grant your CI/CD principal cluster access

If you did **not** set `eks_ci_iam_arn`, add an access entry for your CI user:

```bash
CLUSTER=secure-ntier-dev-eks
aws eks create-access-entry \
  --cluster-name $CLUSTER \
  --principal-arn arn:aws:iam::<ACCOUNT>:user/github-actions-cicd \
  --type STANDARD

aws eks associate-access-policy \
  --cluster-name $CLUSTER \
  --principal-arn arn:aws:iam::<ACCOUNT>:user/github-actions-cicd \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

The CI/CD IAM policy already includes `eks:DescribeCluster` + `eks:ListClusters`
(enough for `aws eks update-kubeconfig`).

## 3. Deploy the application

```bash
# connect kubectl
aws eks update-kubeconfig --name secure-ntier-dev-eks --region eu-west-1

# deploy (kubeconfig + secret materialization + apply + roll + smoke test)
bash kubernetes/scripts/deploy.sh <git-sha> eu-west-1 dev secure-ntier
```

The per-service Deployment/Service/HPA/PDB manifests are **rendered from
`stack.json`** at deploy time by `kubernetes/scripts/render-manifests.sh`
(same idea as the EC2 path rendering `docker-compose.yml`) — adding a service
to `stack.json` is enough; no manifest edits.

Verify:

```bash
kubectl get all -n secure-ntier
curl -s http://<NLB_ENDPOINT>/health        # NLB hostname from `kubectl get svc frontend -n secure-ntier`
```

## 4. Wire the pipelines (optional)

- **GitHub Actions**: set the repository variable `DEPLOY_EKS=true`
  (Settings → Variables → Actions). The `deploy-eks` job in
  `.github/workflows/deploy.yml` then runs after every push to `main`.
- **Jenkins**: tick `DEPLOY_EKS` on the pipeline job (requires `kubectl` on the
  agent).

## 5. Upgrade path to HTTPS + WAF

Replace the plain NLB `frontend` Service with an AWS Load Balancer Controller
`Ingress`:

1. Install the controller (Helm) with IRSA.
2. Add an ACM certificate + associate the existing WAF web ACL.
3. Point the `Ingress` hostname at the ALB and curl `https://app.example.com`.

See [`docs/architecture/kubernetes.md`](../architecture/kubernetes.md) for the
full design and production upgrades.

## Cleanup

```bash
bash kubernetes/scripts/undeploy.sh eu-west-1 secure-ntier-dev-eks   # removes the namespace
# then remove the cluster itself:
#   set enable_eks = false (or terraform destroy) and re-apply
```
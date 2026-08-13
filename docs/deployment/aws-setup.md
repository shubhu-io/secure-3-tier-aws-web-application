# AWS Account Preparation

> ⚠️ **COST WARNING** — Everything on this page is free or near-free, but the
> **deployment** itself creates billable resources. Read
> [`docs/cost-guide.md`](../cost-guide.md) before you `terraform apply`.

## 1. Create an AWS account

https://aws.amazon.com/free → "Create a Free Account". You'll need a payment
method, but the free tier covers many of the resources here for a period.

## 2. Create an IAM user for yourself (never use root keys)

1. Console → **IAM** → **Users** → **Create user**.
2. User name: `devops-admin`.
3. Check **Provide user access to the AWS Management Console**? → not needed.
4. Permissions: Attach policy → **AdministratorAccess** *(only acceptable for
   this learning project; restrict it in a real organization)*.
5. Create user → **Create access key** → "Command Line Interface (CLI)".
6. Save the **Access Key ID** and **Secret Access Key** somewhere safe (a
   password manager, not a repo).

Configure the CLI:

```bash
aws configure
```

```text
AWS Access Key ID [None]: AKIA................
AWS Secret Access Key [None]: ................
Default region name [None]: eu-west-1
Default output format [None]: json
```

Verify:

```bash
aws sts get-caller-identity
```

Expected output (an object with your account ID + ARN).

## 3. Create the Terraform state backend (one-time)

State must live in S3 (shared + encrypted), with DynamoDB locking.

### S3 bucket

```bash
aws s3api create-bucket \
  --bucket <YOUR-UNIQUE-BUCKET> \
  --region <REGION> \
  --create-bucket-configuration LocationConstraint=<REGION>

aws s3api put-bucket-versioning \
  --bucket <YOUR-UNIQUE-BUCKET> \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket <YOUR-UNIQUE-BUCKET> \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Example: `aws s3api create-bucket --bucket my-org-terraform-state --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1`

> Bucket names are globally unique. If you get `BucketAlreadyExists`, pick
> another name.

### DynamoDB lock table

```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region <REGION>
```

Verify:

```bash
aws dynamodb list-tables --region <REGION>
aws s3 ls | grep -i <YOUR-UNIQUE-BUCKET>
```

## 4. Create the CI/CD IAM user

1. Console → IAM → Users → Create user → `github-actions-cicd`.
2. **No console access.** Create access key.
3. After the infrastructure is deployed, attach the policy ARN printed by
   Terraform (`secure-ntier-dev-cicd-policy`) — or inline the JSON from
   [`security/iam/cicd-policy.json`](../../security/iam/cicd-policy.json).
4. Store these keys as GitHub Actions secrets (see [cicd.md](./cicd.md)).

## 5. (Optional) Own a domain for HTTPS + Route 53

To use HTTPS you need a domain you control. In Route 53:

1. Console → **Route 53** → **Hosted zones** → **Create hosted zone**.
2. Domain name: `<YOUR_DOMAIN>` (e.g. `example.com`), Public hosted zone.
3. Note the 4 **NS** (name server) records.
4. At your domain registrar, point the domain's nameservers to those NS values.

Propagation takes minutes to hours. Verify with:

```bash
dig NS example.com +short
```

## Next step

[Deploy infrastructure with Terraform](./terraform.md).

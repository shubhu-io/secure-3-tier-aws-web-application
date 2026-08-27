# GCP CLI (gcloud)

Reference commands for Google Cloud CLI. This project supports GCP as a tertiary cloud (with modules under terraform/cloud/gcp/).

## Installation

```bash
# macOS
brew install google-cloud-sdk

# Ubuntu/Debian
# Add the Cloud SDK repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
   tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.gpg

# Install
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

# Verify
gcloud --version

# Windows: Download from cloud.google.com/sdk/docs/install
```

## Version Check

```bash
gcloud --version
```

## Authentication

```bash
# Login interactively (opens browser)
gcloud auth login

# Login with service account (for CI/CD)
gcloud auth activate-service-account --project <project-id> --key-file <key-file.json>

# Set project
gcloud config set project <project-id>

# List accounts
gcloud auth list

# This project's GCP modules are under terraform/cloud/gcp/
```

## Version Check

```bash
gcloud --version
```

## Compute

```bash
# List instances
gcloud compute instances list

# Create instance
gcloud compute instances create example-instance \
  --zone us-central1-a \
  --machine-type e2-small \
  --image-family debian-11 \
  --image-project debian-cloud

# Delete instance
gcloud compute instances delete example-instance --zone us-central1-a

# This project's GCP implementation uses Cloud SQL, Artifact Registry, and MIG
```

## Container (GKE)

```bash
# Get credentials for GKE cluster
gcloud container clusters get-credentials my-cluster --region us-central1-a

# List clusters
gcloud container clusters list

# This project supports optional GKE deployment alongside EKS/AKS
```

## Artifact Registry

```bash
# List repositories
gcloud artifacts repositories list

# Create repository
gcloud artifacts repositories create my-repo \
  --repository-format=docker \
  --location us-central1

# This project would use Artifact Registry instead of ECR/ACR for container images
```

## Cloud SQL (PostgreSQL)

```bash
# Create Cloud SQL PostgreSQL instance
gcloud sql instances create my-sql-instance \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region us-central1

# List instances
gcloud sql instances list

# This project supports Cloud SQL PostgreSQL on GCP (private IP)
```

## Cloud Storage

```bash
# List buckets
gsutil ls

# Create bucket
gsutil mb gs://my-bucket

# Upload file
gsutil cp local-file.txt gs://my-bucket/

# Download file
gsutil cp gs://my-bucket/remote-file.txt ./

# This project uses Cloud Storage for artifacts and logs
```

## Troubleshooting

```bash
# Common issues
# "gcloud: command not found" - install Google Cloud SDK
# "Please run gcloud init" - initialize gcloud
# "Authentication required" - run gcloud auth login
# "Project not configured" - set project with gcloud config set project

# Debug
gcloud init                          # Interactive setup
gcloud config list                 # Show current configuration
gcloud config set project <id>       # Set project

# This project's GCP support is tertiary (AWS is primary, Azure secondary)
```
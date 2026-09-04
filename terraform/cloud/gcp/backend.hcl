# Store Terraform state remotely even when targeting GCP. S3 is used as a
# cloud-agnostic state store here; swap for gcs backend if preferred.
bucket         = "secure-ntier-tfstate"
key            = "secure-ntier/gcp/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "secure-ntier-tfstate-lock"
encrypt        = true

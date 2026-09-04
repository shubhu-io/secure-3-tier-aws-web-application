# Store Terraform state remotely even when targeting Azure. S3 is used as a
# cloud-agnostic state store here; swap for azurerm backend if preferred.
bucket         = "secure-ntier-tfstate"
key            = "secure-ntier/azure/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "secure-ntier-tfstate-lock"
encrypt        = true

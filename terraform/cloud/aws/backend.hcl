bucket         = "secure-ntier-tfstate"
key            = "secure-ntier/aws/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "secure-ntier-tfstate-lock"
encrypt        = true

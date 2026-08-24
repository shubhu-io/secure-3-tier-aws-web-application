bucket         = "secure-ntier-tfstate"
key            = "secure-ntier/aws/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "secure-ntier-tfstate-lock"
encrypt        = true

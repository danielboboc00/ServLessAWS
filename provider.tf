// Specificam versiunile pentru providerii folositi
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

#Region settings
provider "aws" {
  region = "us-east-2"
}

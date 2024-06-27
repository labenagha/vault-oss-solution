terraform {
  required_version = ">= 1.6.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}
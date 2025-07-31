# Provider Configuration for Team Environment
# terraform {
#   # Terraform Cloud Backend
#   cloud {
#     organization = "goteego" # Replace with your Terraform Cloud organization

#     workspaces {
#       name = "goteego"
#     }
#   }
# }

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
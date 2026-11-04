terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3"
    }
  }

  backend "kubernetes" {
    secret_suffix = "9router"
    namespace     = "default"
  }
}

provider "kubernetes" {}

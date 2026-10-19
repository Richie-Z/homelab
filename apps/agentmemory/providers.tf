terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3"
    }
  }

  # State lives in the cluster so Jenkins runs are not tied to its workspace.
  # Pass credentials at init: the Jenkins agent uses in_cluster_config, local
  # runs use -backend-config="config_path=$HOME/.kube/config".
  backend "kubernetes" {
    secret_suffix = "agentmemory"
    namespace     = "default"
  }
}

# No config_path here: the provider reads KUBE_CONFIG_PATH when set, otherwise
# uses the in-cluster service account.
provider "kubernetes" {}

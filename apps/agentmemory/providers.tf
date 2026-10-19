terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3"
    }
  }

  # State lives in the cluster so Jenkins runs are not tied to its workspace.
  # Jenkins overrides config_path with the kubeconfig credential file.
  backend "kubernetes" {
    secret_suffix = "agentmemory"
    namespace     = "default"
    config_path   = "~/.kube/config"
  }
}

# No config_path here: the provider reads KUBE_CONFIG_PATH when set, otherwise
# falls back to ~/.kube/config.
provider "kubernetes" {}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    sshclient = {
      source  = "luma-planet/sshclient"
      version = "1.0.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.15.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../../admin.kubeconfig"
  }
}

provider "vault" {
  address = "http://vault.localhost"
  token   = yamldecode(file("../../keys/vault-init.yml"))["root_token"]

}

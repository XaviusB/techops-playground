terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.15.0"
    }
  }
}

provider "vault" {
  address = "http://vault.localhost"
  token   = yamldecode(file("../../keys/vault-init.yml"))["root_token"]

}



resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "http://example.com:443"
  disable_iss_validation = "true"
}

resource "vault_policy" "external_secrets" {
  name = "external-secrets"

  policy = <<EOT
path "secrets/*" {
  capabilities = ["read","list"]
}
EOT
}

resource "vault_mount" "kvv2" {
  path        = "secrets"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "time_rotating" "standard" {
  rotation_days = 30
}

resource "random_password" "password" {
  length           = 25
  min_upper        = 5
  min_lower        = 5
  min_numeric      = 5
  min_special      = 5
  special          = true
  override_special = "!#-_=:"
  keepers = {
    expiry = time_rotating.standard.rotation_rfc3339
  }

}

resource "vault_kv_secret_v2" "example" {
  mount               = vault_mount.kvv2.path
  name                = "secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      zip = random_password.password.result,
      foo = "bar"
    }
  )
}

data "vault_kv_secret_v2" "example" {
  mount = vault_mount.kvv2.path
  name  = vault_kv_secret_v2.example.name
}

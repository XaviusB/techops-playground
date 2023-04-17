resource "helm_release" "kong" {
  name             = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  version          = "2.19.0"
  namespace        = "kong"
  create_namespace = true
  values = [
    "${file("../../helm/kong-values.yml")}"
  ]
}

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = "0.24.1"
  namespace        = "vault"
  create_namespace = true
  values = [
    "${file("../../helm/vault-values.yml")}"
  ]
}

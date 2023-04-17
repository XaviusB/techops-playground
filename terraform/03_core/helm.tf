resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.8.1"
  namespace        = "external-secrets"
  create_namespace = true
  values = [
    "${file("../../helm/kong-values.yml")}"
  ]
}

resource "helm_release" "gitea" {
  name             = "gitea"
  repository       = "https://dl.gitea.io/charts"
  chart            = "gitea"
  version          = "8.1.0"
  namespace        = "gitea"
  create_namespace = true
  values = [
    "${file("../../helm/gitea-values.yml")}"
  ]
}

data "sshclient_host" "gitea" {
  hostname                 = "locahost"
  port                     = yamldecode(file("../../helm/gitea-values.yml"))["service"]["ssh"]["nodePort"]
  username                 = "git"
  insecure_ignore_host_key = true
  depends_on               = [helm_release.gitea]
}

data "sshclient_keyscan" "gitea" {
  host_json = data.sshclient_host.gitea.json
}

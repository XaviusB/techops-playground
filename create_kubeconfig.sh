#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

main() {
  local sa
  local namespace
  local kubeconfig
  local "${@}"
  sa="${sa:?Name not set in main function usage}"
  namespace="${namespace:-default}"
  kubeconfig="${kubeconfig:-${PWD}/${sa}.kubeconfig}"

  secret=$(kubectl get sa "${sa}" -o jsonpath="{.secrets[0].name}" -n "${namespace}")
  ca=$(kubectl get secret/"${secret}" -o jsonpath='{.data.ca\.crt}' -n "${namespace}")
  token=$(kubectl get secret/"${secret}" -o jsonpath='{.data.token}' -n "${namespace}" | base64 --decode)
  server=$(kubectl config view -o json | jq -r '.clusters[0].cluster.server')
  cluster_name=$(kubectl config view -o json | jq -r '.clusters[0].name')

  cat <<EOF > "${kubeconfig}"
---
apiVersion: v1
kind: Config
clusters:
- name: ${cluster_name}
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: ${cluster_name}
  context:
    cluster: ${cluster_name}
    namespace: ${namespace}
    user: ${sa}
current-context: ${cluster_name}
users:
- name: ${sa}
  user:
    token: ${token}
EOF


  ARGO_TOKEN="Bearer $(kubectl get secret "${secret}" -n "${namespace}" -o=jsonpath='{.data.token}' | base64 --decode)"
  echo "${ARGO_TOKEN}"


  echo "export KUBECONFIG=\"${kubeconfig}\""

  }

main "${@}"

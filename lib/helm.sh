#!/usr/bin/env bash

function update_helm_repo() {
  log INFO "Upgrading helm repositories"
  helm repo update
}


function helm_install() {
  local repo_name
  local repo_url
  local chart_name
  local chart_version
  local name
  local namespace
  local values_file
  local "${@}"
  repo_name=${repo_name:?need value repo_name}
  repo_url=${repo_url:?need value repo_url}
  chart_name=${chart_name:?need value chart_name}
  chart_version=${chart_version:?need value chart_version}
  name=${name:?need value name}
  namespace=${namespace:?need value namespace}
  values_file=${values_file:-helm/${name}-values.yml}

  log INFO "Installing ${name} from ${repo_name} version ${chart_version}"
  helm repo add "${repo_name}" "${repo_url}"

  kubectl apply --kubeconfig "${KUBECONFIG}" -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${namespace}
EOF

  helm upgrade \
    -i "${name}" "${repo_name}/${chart_name}" \
    --values "${values_file}" \
    --namespace "${namespace}" \
    --version "${chart_version}" \
    --kubeconfig "${KUBECONFIG}"
}

function helm_install_all() {
  helm_install \
    repo_name="kong" \
    repo_url="https://charts.konghq.com" \
    chart_name="kong" \
    chart_version="2.19.0" \
    name="kong" \
    namespace="kong" \
    values_file="helm/kong-values.yml"

  value_file=$(mktemp -p /tmp prometheus-values.XXXXXXXX.yml)
  cp helm/prometheus-values.yml "${value_file}"
  yq e -i '.grafana.adminPassword = env(PASSWORD)' "${value_file}"
  helm_install \
    repo_name="prometheus-community" \
    repo_url="https://prometheus-community.github.io/helm-charts" \
    chart_name="kube-prometheus-stack" \
    chart_version="45.10.1" \
    name="prometheus" \
    namespace="prometheus" \
    values_file="${value_file}"

  helm_install \
    repo_name="argo" \
    repo_url="https://argoproj.github.io/argo-helm" \
    chart_name="argo-workflows" \
    chart_version="0.24.1" \
    name="argo-workflows" \
    namespace="argo-workflows"

  value_file=$(mktemp -p /tmp gitea-values.XXXXXXXX.yml)
  cp helm/gitea-values.yml "${value_file}"
  yq e -i '.gitea.admin.username = "root"' "${value_file}"
  yq e -i '.gitea.admin.password = env(PASSWORD)' "${value_file}"
  helm_install \
    repo_name="gitea-charts" \
    repo_url="https://dl.gitea.io/charts" \
    chart_name="gitea" \
    chart_version="8.1.0" \
    name="gitea" \
    namespace="gitea" \
    values_file="${value_file}"
  wait_for_url url="http://gitea.localhost"

  host_key_file=$(gather_host_keys \
    host="gitea.localhost" \
    port="30022")
  value_file=$(mktemp -p /tmp tmp.argocd-values-XXXXXXXXXX.yml)
  cp helm/argo-cd-values.yml "${value_file}"
  yq e -i '.configs.credentialTemplates.ssh-creds.sshPrivateKey = load_str("keys/my_precious")' "${value_file}"
  yq e -i '.configs.ssh.knownHosts = load_str("'"${host_key_file}"'")' "${value_file}"
  yq e -i '.configs.secret.argocdServerAdminPassword = env(BCRYPT_PASSWORD)' "${value_file}"

  helm_install \
    repo_name="argo" \
    repo_url="https://argoproj.github.io/argo-helm" \
    chart_name="argo-cd" \
    chart_version="5.29.1" \
    name="argo-cd" \
    namespace="argocd" \
    values_file="${value_file}"


  helm_install \
    repo_name="argo" \
    repo_url="https://argoproj.github.io/argo-helm" \
    chart_name="argo-events" \
    chart_version="2.2.0" \
    name="argo-events" \
    namespace="argo-events"
}

export -f update_helm_repo helm_install helm_install_all

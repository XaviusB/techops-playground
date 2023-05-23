#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

export admin="admin.kubeconfig"
export KUBECONFIG="${PWD}/${admin}"
echo "KUBECONFIG=\"${KUBECONFIG}\"" > .env
CURRENT_CONTEXT=$(kubectl config current-context)
export CURRENT_CONTEXT
CURRENT_NAMESPACE=$(yq e '.contexts[] | select(.name == "'"${CURRENT_CONTEXT}"'") | .context.namespace' "${KUBECONFIG}")
export CURRENT_NAMESPACE
export USERNAME="admin"
export PASSWORD="admin"
export GITEA_USERNAME="root"
export GITEA_ORG="myOrg"
export MINIO_USERNAME="adminadmin"  # 8 charts min
export MINIO_PASSWORD="adminadmin"  # 8 charts min

BCRYPT_PASSWORD=$(docker run --rm -it johnstarich/bcrypt -p "${PASSWORD}" -s 14)
export BCRYPT_PASSWORD

shellcheck source=/dev/null
for f in ./lib/*.sh; do source "${f}"; done


main() {
  update_helm_repo
  generate_ssh_key

  helm_install \
    repo_name="kong" \
    repo_url="https://charts.konghq.com" \
    chart_name="kong" \
    chart_version="2.19.0" \
    name="kong" \
    namespace="kong" \
    values_file="helm/kong-values.yml"

  value_file=$(mktemp -p /tmp minio-values.XXXXXXXX.yml)
  cp helm/minio-values.yml "${value_file}"
  yq e -i '.auth.rootUser = env(MINIO_USERNAME)' "${value_file}"
  yq e -i '.auth.rootPassword = env(MINIO_PASSWORD)' "${value_file}"
  helm_install \
    repo_name="bitnami" \
    repo_url="https://charts.bitnami.com/bitnami" \
    chart_name="minio" \
    chart_version="12.2.6" \
    name="minio" \
    namespace="minio" \
    values_file="${value_file}"

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
  wait_for_url url="http://argocd.localhost"
  argocd login cd.argoproj.io --core --kube-context kind-selfdestroy

  helm_install \
    repo_name="argo" \
    repo_url="https://argoproj.github.io/argo-helm" \
    chart_name="argo-events" \
    chart_version="2.2.0" \
    name="argo-events" \
    namespace="argo-events"

  create_gitea_org \
    org_name="${GITEA_ORG}"

  create_gitea_org_label \
    org_name="${GITEA_ORG}" \
    label_name="create_sandbox" \
    label_color="ff0000" \
    label_description="my-label" \
    exclusive="true"

  for repo in ./repos/*; do
    if [ -d "${repo}" ]; then
      repo_name=$(basename "${repo}")

      create_gitea_repo \
        org_name="${GITEA_ORG}" \
        repo_name="${repo_name}" \
        repo_description="${repo_name}"
      add_repo_key \
        org_name="${GITEA_ORG}" \
        repo_name="${repo_name}" \
        key_title="my_precious" \
        key_path="keys/my_precious.pub"
      git_init \
        org_name="${GITEA_ORG}" \
        folder="${repo}" \
        repo_name="${repo_name}"

      events=(pull_request_label)
      add_repo_webhook \
        org_name="${GITEA_ORG}" \
        repo_name="${repo_name}" \
        url="http://webhook-eventsource-svc.events.svc.cluster.local:12000/labeling" \
        events="${events[*]}"
      create_app \
        org_name="${GITEA_ORG}" \
        repo_name="${repo_name}"

      kubectl create secret generic my-precious \
        --from-file=keys/my_precious \
        -n "${repo_name}" \
        --kubeconfig "${KUBECONFIG}" || true
    fi

    kubectl config set-context "${CURRENT_CONTEXT}" \
      --namespace=argocd \
      --kubeconfig "${KUBECONFIG}"
    sleep 5

    argocd app sync "${repo_name}" \
      --force \
      --async \
      --kube-context kind-selfdestroy 2>/dev/null || true
  done

  log DEBUG "Following ingress available"
  for url in $(kubectl get ingress -A -o yaml | yq '.items[].spec.rules[].host'); do
    echo "http://${url}";
  done
}

mouseTrap () {
  kubectl config set-context "${CURRENT_CONTEXT}" --namespace="${CURRENT_NAMESPACE}"
}

trap 'mouseTrap' EXIT
main "${@}"

#!/usr/bin/env bash

function create_app() {
  local repo_name
  local org_name
  local "${@}"
  repo_name=${repo_name:?need value repo_name}
  org_name=${org_name:?need value org_name}

  kubectl apply --kubeconfig "${KUBECONFIG}" -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${repo_name}
  namespace: argocd
spec:
  destination:
    namespace: ${repo_name}
    server: https://kubernetes.default.svc
  project: default
  source:
    path: ./
    repoURL: git@gitea-ssh.gitea.svc.cluster.local:${org_name}/${repo_name}.git
    targetRevision: master
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
}

export -f create_app

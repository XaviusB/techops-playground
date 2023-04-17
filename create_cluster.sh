#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

export kubeconfig="${PWD}/admin.kubeconfig"

if [ -f "${kubeconfig}" ]; then
  echo WARN "Cluster has already been created"
  exit 1
fi

mkdir -p /tmp/playground/data/containerd

kind create cluster \
	--config cluster.yml \
	--kubeconfig "${kubeconfig}" \
	--retain

export KUBECONFIG="${kubeconfig}"
kubectl cluster-info --context kind-selfdestroy --kubeconfig admin.kubeconfig
echo export "KUBECONFIG=\"${kubeconfig}\""

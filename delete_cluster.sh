#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

kind delete cluster --name selfdestroy || true

echo "Deleting kubeconfig files"
rm -f ./*.kubeconfig
rm -f ./keys/my_precious \
  ./keys/my_precious.pub \
  ./keys/vault-init.json
ssh-keygen \
  -f "/home/xavier/.ssh/known_hosts" \
  -R "[gitea.localhost]:30022" || true
rm -rf application/.git
find . -name terraform.tfstate -delete
find . -name terraform.tfstate.backup -delete
# find . -name .terraform -type d -exec rm -rf {} +
find . -name .terraform.lock.hcl -delete

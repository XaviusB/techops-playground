#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

kind delete cluster --name selfdestroy || true

echo "Deleting kubeconfig files"
rm -f ./*.kubeconfig
rm -f ./ssh_keys/my_precious ./ssh_keys/my_precious.pub
ssh-keygen -f "/home/xavier/.ssh/known_hosts" -R "[gitea.localhost]:30022" || true
rm -rf application/.git

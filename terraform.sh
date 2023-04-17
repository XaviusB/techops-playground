#!/bin/bash

set -euo pipefail
ROOT_FOLDER="${PWD}"
export ROOT_FOLDER

mapfile -t files < <(find "${ROOT_FOLDER}/lib/" -type f -name "*.sh")
# shellcheck source=/dev/null
for f in "${files[@]}"; do source "${f}"; done

for dir in ./terraform/*/     # list directories in the form "/tmp/dirname/"
do
  log INFO "Processing ${dir}"
  pushd "${dir}" > /dev/null

  if [ -f "before.sh" ]; then
    log INFO "Running before.sh"
    ./before.sh
  fi
  tmp_state=$(mktemp -p /tmp terraform-state.XXXXXXXX.json)

  terraform fmt -recursive
  terraform init -upgrade
  terraform plan -out "${tmp_state}"
  terraform apply -auto-approve "${tmp_state}"

  if [ -f "after.sh" ]; then
    log INFO "Running after.sh"
    ./after.sh
  fi

  popd > /dev/null
done

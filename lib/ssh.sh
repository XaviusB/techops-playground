#!/usr/bin/env bash

function generate_ssh_key() {
  if [ ! -d ./ssh_keys ]; then
    mkdir ./ssh_keys
  fi
  if [ ! -f ./ssh_keys/my_precious ]; then
    log WARN "Generating SSH key"
    ssh-keygen -t ed25519 -f ./ssh_keys/my_precious -q -N ""
  else
    log INFO "SSH key already exists"
  fi
  export GIT_SSH_COMMAND="ssh -i ./ssh_keys/my_precious"
  ssh-add ./ssh_keys/my_precious
}


function gather_host_keys() {
  local host
  local port
  local "${@}"
  host=${host:?need value host}
  port=${port:-22}

  mapfile -t scanned_keys < <(ssh-keyscan -p "${port}" "${host}" 2>/dev/null)
  tmp_keys=$(mktemp -p /tmp tmp.keys-XXXXXXXXXX)
  for key in "${scanned_keys[@]}"; do
    echo "${key}" >> "${tmp_keys}"
    echo "${key/\[gitea.localhost\]:30022/gitea-ssh.gitea.svc.cluster.local}" >> "${tmp_keys}"
  done
  echo "${tmp_keys}"
}

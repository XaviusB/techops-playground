#!/usr/bin/env bash

function vault_init() {
  ROOT_FOLDER=${ROOT_FOLDER:-"."}
  # FIXME find out what command is failing
  set +e
  is_initialized=$(vault status -format=yaml | yq '.initialized')

  if [ "${is_initialized}" = "true" ]; then
    log INFO "Vault is already initialized"
  else
    log WARN "Vault is not initialized... Initializing"
    vault operator init -key-shares=1 -key-threshold=1 -format=yaml > "${ROOT_FOLDER}/keys/vault-init.yml"
  fi
  vault_unseal_key_b64=$(yq '.unseal_keys_b64[0]' "${ROOT_FOLDER}/keys/vault-init.yml")
  VAULT_TOKEN=$(yq '.root_token' "${ROOT_FOLDER}/keys/vault-init.yml")
  export VAULT_TOKEN

  is_unseal=$(vault status -format=yaml | yq '.sealed')

  if [ "${is_unseal}" = "true" ]; then
    log WARN "Vault is sealed... Unsealing"
    vault operator unseal "${vault_unseal_key_b64}" 1>/dev/null
  else
    log INFO "Vault is already unsealed"
  fi
  # FIXME find out what command is failing above
  set -e
}

export -f vault_init

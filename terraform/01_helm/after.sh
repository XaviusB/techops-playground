#!/bin/bash

set -euo pipefail

wait_for_url url="http://vault.localhost/ui/vault/init"
vault_init

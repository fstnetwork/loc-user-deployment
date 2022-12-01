#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [ "$#" -ne 2 ]; then
  echo "usage: $(basename "$0") [vault address] [environment name]"
  exit 87
fi

export VAULT_ADDR=$1
ENVIRONMENT_NAME=$2
NAMESPACE=$ENVIRONMENT_NAME
SECRET_ENGINE_NAME=$ENVIRONMENT_NAME
REPOSITORY_POLICY_NAME="$ENVIRONMENT_NAME-repository"
REPOSITORY_ROLE_NAME="$ENVIRONMENT_NAME-repository"
REPOSITORY_SA_NAME="$ENVIRONMENT_NAME-saffron-repository"
RUNTIME_POLICY_NAME="$ENVIRONMENT_NAME-runtime"
RUNTIME_ROLE_NAME="$ENVIRONMENT_NAME-runtime"
RUNTIME_SA_NAME="$ENVIRONMENT_NAME-saffron-default-runtime"

# create secret engine
vault secrets enable -version=2 -path "$SECRET_ENGINE_NAME" kv

# create repository role
vault policy write "$REPOSITORY_POLICY_NAME" - <<EOF
path "$SECRET_ENGINE_NAME/*" {
  capabilities = ["create", "update", "patch", "delete"]
}
EOF

vault write "auth/kubernetes/role/$REPOSITORY_ROLE_NAME" \
  "bound_service_account_names=$REPOSITORY_SA_NAME" \
  "bound_service_account_namespaces=$NAMESPACE" \
  "policies=$REPOSITORY_POLICY_NAME" \
  ttl=20m

# create runtime role
vault policy write "$RUNTIME_POLICY_NAME" - <<EOF
path "$SECRET_ENGINE_NAME/*" {
  capabilities = ["read"]
}
EOF

vault write "auth/kubernetes/role/$RUNTIME_ROLE_NAME" \
  "bound_service_account_names=$RUNTIME_SA_NAME" \
  "bound_service_account_namespaces=$NAMESPACE" \
  "policies=$RUNTIME_POLICY_NAME" \
  ttl=20m
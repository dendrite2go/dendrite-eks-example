#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"
source "${BIN}/lib-sed-ext.sh"
source "${BIN}/lib-template.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

PUBLIC_KEY="$(cat "${ROOT_PRIVATE_KEY}.pub")"

instantiate-template "${PROJECT}/kubernetes/cluster" '.yaml'

"${BIN}/aws-eksctl.sh" create nodegroup \
  -f "${PROJECT}/kubernetes/nodegroup-local.yaml"

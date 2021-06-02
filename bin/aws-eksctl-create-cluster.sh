#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/verbose.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

"${BIN}/aws-eksctl.sh" create cluster \
  --name "${ENSEMBLE_NAME}" \
  --region "${AWS_REGION}" \
  --with-oidc \
  --ssh-access \
  --ssh-public-key 'jeroen' \
  --managed

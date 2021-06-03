#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/verbose.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

if [[ -z "${EKS_INSTANCE_TYPES}" ]]
then
  EKS_INSTANCE_TYPES='t3.medium'
fi

"${BIN}/aws-eksctl.sh" "${FLAGS_INHERIT[@]}" create cluster \
  --name "${ENSEMBLE_NAME}" \
  --region "${AWS_REGION}" \
  --with-oidc \
  --ssh-access \
  --ssh-public-key "${EC2_KEY_PAIR}" \
  --managed \
  --nodes 3 \
  --instance-types "${EKS_INSTANCE_TYPES}"

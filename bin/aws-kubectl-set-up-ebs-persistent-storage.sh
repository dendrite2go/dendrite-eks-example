#!/bin/bash

# Also add policy with EC2 permissions: CreateVolume, AttachVolume, and CreateTags to NodeInstanceRole.

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
LOCAL_DIR="${PROJECT}/data/local"

source "${BIN}/lib-verbose.sh"
source "${BIN}/lib-sed-ext.sh"
source "${BIN}/lib-template.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

function aws() {
  "${BIN}/aws.sh" "$@"
}

function kubectl() {
  "${BIN}/aws-kubectl.sh" "$@"
}

mkdir -p "${LOCAL_DIR}"

(
  cd "${LOCAL_DIR}" || exit 1
  curl -o example-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v0.9.0/docs/example-iam-policy.json
  ls -l

  aws iam detach-role-policy \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy" \
    --role-name AmazonEKS_EBS_CSI_DriverRole

  aws iam delete-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy" || true
  aws iam create-policy --policy-name AmazonEKS_EBS_CSI_Driver_Policy --policy-document file://example-iam-policy.json

  OIDC_ISSUER="$(aws eks describe-cluster --name "${ENSEMBLE_NAME}" --query "cluster.identity.oidc.issuer" --output text | sed -e 's@^.*/@@')"
  log "OIDC_ISSUER=[${OIDC_ISSUER}]"

  instantiate-template "${PROJECT}/kubernetes/trust-policy" '.json'
  mv "${PROJECT}/kubernetes/trust-policy-local.json" .

  aws iam delete-role --role-name 'AmazonEKS_EBS_CSI_DriverRole' || true
  aws iam create-role \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --assume-role-policy-document "file://trust-policy-local.json"

  aws iam attach-role-policy \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy" \
    --role-name AmazonEKS_EBS_CSI_DriverRole

  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
)
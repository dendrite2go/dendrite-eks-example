#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/verbose.sh"
source "${BIN}/create-local-settings.sh"
source "${PROJECT}/etc/settings-local.sh"

mkdir -p "${PROJECT}/data/local"

(
  cd "${PROJECT}/data/local"
  curl -o example-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.0.0/docs/example-iam-policy.json

  function get-attached-role() {
    local POLICY_ARN="$1"
    ( "${BIN}/aws.sh" iam list-entities-for-policy --policy-arn "${POLICY_ARN}" --query='PolicyRoles[0].RoleName' || true) | tr -d \"
  }
  ATTACHED_ROLE="$(get-attached-role "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy")"
  info "ATTACHED_ROLE=[${ATTACHED_ROLE}]"
  if [[ -n "${ATTACHED_ROLE}" ]] && [[ ".${ATTACHED_ROLE}" != '.null' ]]
  then
    "${BIN}/aws.sh" iam detach-role-policy --role-name "${ATTACHED_ROLE}" --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy"
  fi
  "${BIN}/aws.sh" iam delete-policy \
        --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy \
    || true

  "${BIN}/aws.sh" iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
    --policy-document file://example-iam-policy.json

  "${BIN}/aws-eksctl.sh" create iamserviceaccount \
    --name 'ebs-csi-controller-sa' \
    --region "${AWS_REGION}" \
    --namespace 'kube-system' \
    --cluster "${ENSEMBLE_NAME}" \
    --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy" \
    --approve \
    --override-existing-serviceaccounts

  function get-role-name() {
    local STACK_NAME="$1"
    "${BIN}/aws.sh" cloudformation describe-stacks \
      --region "${AWS_REGION}" \
      --stack-name "${STACK_NAME}" \
      --query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' \
      --output text
  }
  ROLE_NAME="$(get-role-name "eksctl-${ENSEMBLE_NAME}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa")"
  info "ROLE_NAME=[${ROLE_NAME}]"

  "${BIN}/aws-helm.sh" repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
  "${BIN}/aws-helm.sh" repo update

  "${BIN}/aws-helm.sh" upgrade -install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set enableVolumeResizing=true \
    --set enableVolumeSnapshot=true \
    --set serviceAccount.controller.create=false \
    --set serviceAccount.controller.name=ebs-csi-controller-sa
)

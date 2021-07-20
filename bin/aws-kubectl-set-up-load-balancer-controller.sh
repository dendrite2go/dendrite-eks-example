#!/bin/bash

# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
LOCAL_DATA="${PROJECT}/data/local"

source "${BIN}/lib-verbose.sh"

LOAD_BALANCER_CONTROLLER_VERSION='v2_ga'

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

ENSEMBLE_HYPHENS="$(echo "${ENSEMBLE_NAME}" | tr '_' '-')"

function aws() {
  "${BIN}/aws.sh" "$@"
}

function helm() {
  "${BIN}/aws-helm.sh" "$@"
}

function get-stack-resources() {
  aws cloudformation list-stack-resources --region "${AWS_REGION}" --stack-name "eksctl-${ENSEMBLE_HYPHENS}-cluster" \
    | "${BIN}/yq.sh" -y '.StackResourceSummaries[] | {"l":.LogicalResourceId,"p":.PhysicalResourceId}' \
    | sed -e 's/^[A-Za-z]*: //' -e 's/^---$/|/' \
    | tr '|\012' '\012|'
}

function get-stack-resource() {
  local LOGICAL_NAME="$1"
  get-stack-resources \
    | sed -e "/^[|]${LOGICAL_NAME}[|]/!d" -e 's/[|]$//' -e 's/^.*[|]//'
}

OIDC_ISSUER="$(aws eks describe-cluster --region "${AWS_REGION}" --name "${ENSEMBLE_HYPHENS}" --query "cluster.identity.oidc.issuer" --output text)"
info "OIDC_ISSUER=[${OIDC_ISSUER}]"
OIDC_ISSUER_ID="$(echo "${OIDC_ISSUER}" | sed -e 's:^.*/::')"
info "OIDC_ISSUER_ID=[${OIDC_ISSUER_ID}]"

OIDC_PROVIDER_ARN="$(aws iam list-open-id-connect-providers | sed -e "/${OIDC_ISSUER_ID}/!d" -e 's/^ *"Arn": "//' -e 's/"$//')"
info "OIDC_PROVIDER_ARN=[${OIDC_PROVIDER_ARN}]"

if [[ -z "${OIDC_PROVIDER_ARN}" ]]
then
  error "Configure a OIDC provider for cluster ${ENSEMBLE_HYPHENS} first"
fi

mkdir -p "${LOCAL_DATA}"
(
  cd "${LOCAL_DATA}"

  if [[ -z "$(aws iam list-policies | grep ':policy/AWSLoadBalancerControllerIAMPolicy')" ]]
  then
    curl -s -o 'eks_load_balancer_controller_iam_policy.json' "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LOAD_BALANCER_CONTROLLER_VERSION}/docs/install/iam_policy.json"
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://eks_load_balancer_controller_iam_policy.json
  else
    info 'Policy AWSLoadBalancerControllerIAMPolicy was already installed'
  fi

  if [[ -z "$(aws iam list-policies | grep ':policy/AWSLoadBalancerControllerAdditionalIAMPolicy')" ]]
  then
    curl -s -o 'iam_policy_v1_to_v2_additional.json' curl -o iam_policy_v1_to_v2_additional.json "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LOAD_BALANCER_CONTROLLER_VERSION}/docs/install/iam_policy_v1_to_v2_additional.json"
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerAdditionalIAMPolicy \
        --policy-document file://iam_policy_v1_to_v2_additional.json
  else
    info 'Policy AWSLoadBalancerControllerAdditionalIAMPolicy was already installed'
  fi

  SERVICE_ROLE="$(get-stack-resource ServiceRole)"
  info "SERVICE_ROLE=[${SERVICE_ROLE}]"
  if [[ -z "${SERVICE_ROLE}" ]]
  then
    error 'Missing service role'
  fi

  VPC="$(get-stack-resource VPC)"
  info "VPC=[${VPC}]"
  if [[ -z "${VPC}" ]]
  then
    error 'Missing Virtual Private Cloud (VPC)'
  fi

  aws iam attach-role-policy \
        --role-name "${SERVICE_ROLE}" \
        --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
    || true

  aws iam attach-role-policy \
        --role-name "${SERVICE_ROLE}" \
        --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerAdditionalIAMPolicy \
    || true

  "${BIN}/aws-kubectl.sh" apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

  helm repo add eks https://aws.github.io/eks-charts
  helm repo update

  "${BIN}/aws-eksctl.sh" --region "${AWS_REGION}" create iamserviceaccount \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --override-existing-serviceaccounts \
    --approve --cluster "${ENSEMBLE_HYPHENS}" \
    --attach-role-arn "arn:aws:iam::772287713832:role/${SERVICE_ROLE}"

  helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
      --set region="${AWS_REGION}" \
      --set vpcId="${VPC}" \
      --set clusterName=cluster-name \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      -n kube-system
)

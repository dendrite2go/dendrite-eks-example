#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/verbose.sh"

"${BIN}/create-local-settings.sh"

source "${PROJECT}/etc/settings-local.sh"

ENSEMBLE_HYPHENS="$(echo "${ENSEMBLE_NAME}" | tr '_' '-')"

"${BIN}/aws.sh" --region "${AWS_REGION}" ecr get-login-password \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

function transfer() {
  local NAME="$1"
  local TAG="$2"
  log "Transfer '${NAME}:${TAG}' to ${ENSEMBLE_HYPHENS} ECR"
  docker pull "${NAME}:${TAG}"
  docker tag "${NAME}:${TAG}" "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_PREFIX}${NAME}:${TAG}"
  docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_PREFIX}${NAME}:${TAG}"
}

function tag-and-push() {
  local PREFIX=''
  if [[ ".$1" = '.--prefix' ]]
  then
    PREFIX="$2"
    shift 2
  fi
  local NAME="$1"
  local TAG="$2"
  log "Transfer '${PREFIX}${NAME}:${TAG}' to ${ENSEMBLE_HYPHENS} ECR"
  docker tag "${PREFIX}${NAME}:${TAG}" "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_PREFIX}${NAME}:${TAG}"
  docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_PREFIX}${NAME}:${TAG}"
}

transfer rust "${RUST_TAG}"
transfer node "${NODE_TAG}"
transfer nginx "${NGINX_TAG}"
transfer gcr.io/distroless/cc-debian10 "nonroot"
transfer dendrite2go/build-protoc latest
transfer axoniq/axonserver "${AXON_VERSION}"
transfer dendrite2go/config-manager "${CONFIG_MANAGER_VERSION}"
transfer elasticsearch "${ELASTIC_SEARCH_VERSION}"
tag-and-push --prefix "dendrite2go/" "${ENSEMBLE_HYPHENS}-proxy" "${ENSEMBLE_IMAGE_VERSION}"
tag-and-push --prefix "dendrite2go/" "${ENSEMBLE_HYPHENS}-present" "${ENSEMBLE_IMAGE_VERSION}"
docker tag "dendrite2go/rustic-core:${ENSEMBLE_IMAGE_VERSION}" "dendrite2go/rustic-api:${ENSEMBLE_IMAGE_VERSION}"
tag-and-push --prefix "dendrite2go/" "${ENSEMBLE_HYPHENS}-api" "${ENSEMBLE_IMAGE_VERSION}"

#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
CONTEXT_HOME="${PROJECT}/docker/context/home"

mkdir -p "${HOME}/.aws"

CWD="$(pwd)"

TTY_FLAG=()
if [[ ".$1" = '.-t' ]]
then
  TTY_FLAG=(-t)
fi

docker run --rm "${TTY_FLAG[@]}" -i \
  -v "${CONTEXT_HOME}/aws:/root/.aws" \
  -v "${CONTEXT_HOME}/kube:/root/.kube" \
  -v "${PROJECT}:${PROJECT}" \
  -w "${CWD}" \
  'amazon/aws-cli' "$@"

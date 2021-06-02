#!/bin/bash

# https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
CONTEXT_HOME="${PROJECT}/docker/context/home"

TTY_FLAG=()
if [[ ".$1" = '.-t' ]]
then
  TTY_FLAG=(-t)
  shift
fi

docker run --rm "${TTY_FLAG[@]}" -i \
  -v "${CONTEXT_HOME}/kube:/root/.kube" \
  -v "${CONTEXT_HOME}/aws:/root/.aws" \
  -v "${PROJECT}:${PROJECT}" \
  -w "${CWD}" \
  weaveworks/eksctl:0.50.0 "$@"

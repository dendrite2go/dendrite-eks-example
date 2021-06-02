#!/bin/bash

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
  -v "${CONTEXT_HOME}/aws:/root/.aws" \
  -v "${CONTEXT_HOME}/kube:/root/.kube" \
  -v "${CONTEXT_HOME}/cache:/root/.cache" \
  -v "${CONTEXT_HOME}/config:/root/.config" \
  -v "${PROJECT}:${PROJECT}" \
  -w "$(pwd)"\
  jshimko/kube-tools-aws:3.6.0 \
  helm "$@"

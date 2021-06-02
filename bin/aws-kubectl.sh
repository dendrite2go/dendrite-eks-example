#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"
CONTEXT_HOME="${PROJECT}/docker/context/home"

source "${BIN}/lib-verbose.sh"

DOCKER_FLAGS=()
if [[ ".$1" = '.-t' ]]
then
  DOCKER_FLAGS[${#DOCKER_FLAGS[@]}]="$1"
  shift
fi

if [[ ".$1" = '.--docker-flags' ]]
then
  shift
  while [[ ".$1" != '.--' ]]
  do
    DOCKER_FLAGS[${#DOCKER_FLAGS[@]}]="$1"
    shift
  done
  shift
fi

docker run --rm -i \
  -v "${CONTEXT_HOME}/aws:/root/.aws" \
  -v "${CONTEXT_HOME}/kube:/root/.kube" \
  -v "${PROJECT}:${PROJECT}" \
  -w "$(pwd)" \
  "${DOCKER_FLAGS[@]}" \
  jshimko/kube-tools-aws:3.6.0 \
  kubectl "$@"

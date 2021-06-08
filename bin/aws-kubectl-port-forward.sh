#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"

source "${BIN}/lib-verbose.sh"

LOCAL_PORT="$1" ; shift
CONTAINER_PORT="$1" ; shift
if [[ ".$1" = '.--address' ]]
then
  BIND="$2"
  shift 2
else
  BIND='127.0.0.1'
fi

DOCKER_FLAGS=( --publish "${BIND}:${LOCAL_PORT}:${LOCAL_PORT}" )

"${BIN}/aws-kubectl.sh" "${FLAGS_INHERIT[@]}" --docker-flags "${DOCKER_FLAGS[@]}" -- port-forward "$@" --address '0.0.0.0' "${LOCAL_PORT}:${CONTAINER_PORT}"

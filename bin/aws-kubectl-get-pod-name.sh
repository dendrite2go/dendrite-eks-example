#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"

source "${BIN}/lib-verbose.sh"

COMPONENT_NAME="$1"

"${BIN}/aws-kubectl.sh" get pods --selector="app.kubernetes.io/name=${COMPONENT_NAME}" -o jsonpath='{.items[0]..metadata.name}' | grep .

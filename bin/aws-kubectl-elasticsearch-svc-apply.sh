#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

"${BIN}/create-local-settings.sh"
source "${PROJECT}/etc/settings-local.sh"

source "${BIN}/lib-verbose.sh"
source "${BIN}/lib-sed-ext.sh"
source "${BIN}/lib-template.sh"

BASE="${PROJECT}/kubernetes/elastic-search-svc"
SERVICE="${BASE}-local.yaml"

log "Creating service: [${SERVICE}]"
instantiate-template "${BASE}" '.yaml'

"${BIN}/aws-kubectl.sh" apply -f "${SERVICE}"

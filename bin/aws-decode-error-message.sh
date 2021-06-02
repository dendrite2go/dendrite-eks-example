#!/bin/bash

BIN="$(cd "$(dirname "$0")" ; pwd)"

"${BIN}/aws.sh" sts decode-authorization-message --encoded-message "$1" \
  | "${BIN}/yq.sh" -r .DecodedMessage \
  | "${BIN}/yq.sh" -y .

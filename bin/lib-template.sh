#!/usr/bin/false

function re-protect() {
    sed "${SED_EXT}" -e 's/([[]|[]]|[|*?^$()/])/\\\1/g' -e 's/$/\\/g' -e '$s/\\$//'
}

function substitute() {
    local VARIABLE="$1"
    local TARGET="$2"
    local VALUE="$(eval "echo \"\${${VARIABLE}}\"" | re-protect)"
    log "VALUE=[${VALUE}]"
    if [[ -n "$(eval "echo \"\${${VARIABLE}+true}\"")" ]]
    then
        sed "${SED_EXT}" -e "s/[\$][{]${VARIABLE}[}]/${VALUE}/g" "${TARGET}" > "${TARGET}~"
        mv "${TARGET}~" "${TARGET}"
    fi
}

function instantiate-template() {
  local LOCAL='-local'
  if [[ ".$1" = '.--bare' ]]
  then
    LOCAL=''
    shift
  fi
  local BASE="$1"
  local EXTENSION="$2"
  local TEMPLATE="${BASE}-template${EXTENSION}"
  local TARGET="${BASE}${LOCAL}${EXTENSION}"
  local VARIABLES="$(tr '$\012' '\012$' < "${TEMPLATE}" | sed -e '/^[{][A-Za-z_][A-Za-z0-9_]*[}]/!d' -e 's/^[{]//' -e 's/[}].*//')"

  cp "${TEMPLATE}" "${TARGET}"
  for VARIABLE in ${VARIABLES}
  do
      log "VARIABLE=[${VARIABLE}]"
      substitute "${VARIABLE}" "${TARGET}"
  done
  "${SILENT}" || diff -u "${TEMPLATE}" "${TARGET}" || true
}

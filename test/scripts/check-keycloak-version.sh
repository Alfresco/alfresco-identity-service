#!/bin/bash

. "common.func"

ARGS=$@
for arg in $ARGS; do
  eval "$arg"
done

# shellcheck disable=SC2154
IDS_BASE_URL="${ids_base_url}"
# shellcheck disable=SC2154
# IDS full path
IDS_HOME="${ids_home}"

MAX_TRIES=10

get_token() {
  attempt=1
  while [ -z "${TOKEN}" ] && [ $attempt -lt "${MAX_TRIES}" ]; do
    TOKEN="$(curl --insecure --silent --show-error "$IDS_BASE_URL/auth/realms/master/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=admin" \
      -d "password=admin" \
      -d "grant_type=password" \
      -d "client_id=admin-cli" | jq -r ".access_token")"
    sleep 2
    attempt=$((attempt + 1))
  done
}

log_info "Getting the expected Keycloak version from: ${IDS_HOME}"
EXPECTED_VERSION=$(< "${IDS_HOME}/version.txt"  cut -f4 -d' ')
log_info "Got expected Keycloak version as: ${EXPECTED_VERSION}"

get_token
ACTUAL_VERSION="$(curl -s "${IDS_BASE_URL}/auth/admin/serverinfo" -H "Authorization: Bearer ${TOKEN}" | jq -r ".systemInfo.version")"
log_info "Got actual Keycloak version as: ${ACTUAL_VERSION}"

if [ "${ACTUAL_VERSION}" = "${EXPECTED_VERSION}" ]; then
  log_info "PASS: The actual and expected versions are equal."
  exit 0
else
  log_info "Fail: Expected Keycloak version: ${EXPECTED_VERSION} but got: ${ACTUAL_VERSION}"
  exit 1
fi

#!/bin/bash

#
# This script adds (configurable) SAML and OpenLDAP configuration to default alfresco realm.
# It also sets a pre-configured keystore to cater for SAML signed responses.
# It runs after deploy_identity_service.sh, before any tests are run
#

. "test/helm/common.func"

HOST=${HOST:-${bamboo_inject_dbpurl}}
CONFIG_TEMPLATES_DIR=test/helm
bamboo_pingfederate_connection_enable=true
is_openldap_enabled=true

namespace=$(get_namespace)

PODS_COUNTER=0

# sleep seconds
PODS_SLEEP_SECONDS=10

# counters limit
PODS_COUNTER_MAX=90

AIS_URL="https://${HOST}/auth/"
log_info "Check if AIS has started at $AIS_URL"
while [ "$PODS_COUNTER" -lt "$PODS_COUNTER_MAX" ]; do
    statusCode=$(curl -L --insecure $AIS_URL -o /dev/null -w '%{http_code}\n' -s)
    if [ $statusCode -eq  "200" ]; then
        log_info "AIS is up and running"
        break
    fi
    PODS_COUNTER=$((PODS_COUNTER + 1))
    log_info "AIS is sleeping - Counter $PODS_COUNTER - Status code is $statusCode"
    sleep "$PODS_SLEEP_SECONDS"
    continue
done
if [ "$PODS_COUNTER" -ge "$PODS_COUNTER_MAX" ]; then
    log_info "AIS did not started properly - exit"
    exit 1
fi

echo "Obtaining admin token"
TOKEN=$(curl --insecure --silent --show-error -X POST "https://${HOST}/auth/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r ".access_token")

# Configure LDAP Storage Provider
# if is_openldap_enabled; then
    log_info "Adding LDAP config"

    jq '.config.connectionUrl[0]="ldap://'openldap-$TRAVIS_BUILD_NUMBER':389"' ${CONFIG_TEMPLATES_DIR}/ldap-auth-defn.json \
        > ./ldap-auth-defn.json

    curl --insecure -v --silent --show-error -X POST "https://${HOST}/auth/admin/realms/alfresco/components" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        --data "@./ldap-auth-defn.json"
# else
#     log_info "Skipping LDAP config"
# fi
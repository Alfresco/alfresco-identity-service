#!/bin/bash

log_info() {
    echo "info::: ${1}"
}

log_error() {
    echo "error::: ${1}"
    exit 1
}

check_var() {
    if [ -z "${1}" ]; then
        log_error "${2} env variable is mandatory"
    fi
}

# AIMS properties
IDP_ID='saml'
REALM='alfresco'
REALM_KEY_PROVIDER_NAME="${IDS_KEY_PROVIDER_NAME:-dbp-sso-rsa}"

SAML_CLIENT_ID="$(./auth0-api.sh getId "${1}")"
HOST_IP="${1}"
IDS_BASE_URL="https://${HOST_IP}"

check_var "$HOST_IP"        "HOST_IP"
check_var "$SAML_CLIENT_ID" "AUTH0_CLIENT_ID"
check_var "$IDS_BASE_URL" "IDS_BASE_URL"

log_info "Using IDS_BASE_URL '${IDS_BASE_URL}'"
log_info "Get the admin cli token ..."

MAX_TRIES=10

get_token() {
attempt=1
while  [ -z "${TOKEN}" ]  &&  [ $attempt -lt "${MAX_TRIES}" ]  ; do
  TOKEN="$(curl --insecure --silent --show-error "$IDS_BASE_URL/auth/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r ".access_token")"
   sleep 2
   attempt=$((attempt+1))
done
}

run_and_check_000_status_code(){
attempt=1
STATUS_CODE=1
${1}
while [[ "${STATUS_CODE}" -eq "000" ]]; do
  ${1}
  log_info "Retrying to run \"${1}\"... (attempt: $((attempt++)))"
  sleep 2
  if [ "${attempt}" -gt "${MAX_TRIES}" ]; then
    log_error "Error on configuring SAML. Cancelling set up after ${MAX_TRIES} seconds"
    exit 1
  fi
done
}

configure_realm() {
get_token
# Check if the realm key provider already exists
KEY_NAME="$(curl -s "${IDS_BASE_URL}/auth/admin/realms/${REALM}/components?type=org.keycloak.keys.KeyProvider&name=${REALM_KEY_PROVIDER_NAME}" \
    -H "Authorization: Bearer ${TOKEN}" | jq '. | .[].name')"

log_info "Setting the realm key provider '${REALM_KEY_PROVIDER_NAME}' ..."

if [ -n "${KEY_NAME}" ]; then
    log_info "The realm key provider '${REALM_KEY_PROVIDER_NAME}' already exists."
else
    # Set the realm keys (i.e. private key and certificate. For example, the certificate that other party needs to validate the AIMS signed SAML message)
    KEYS_PAYLOAD="$(cat $PWD/config-files/realmRsaKeys.json)"
    get_token
    STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" \
        "${IDS_BASE_URL}/auth/admin/realms/${REALM}/components" \
        --compressed \
        -H "Content-Type: application/json;charset=utf-8" \
        -H "Authorization: Bearer ${TOKEN}" \
        --data "${KEYS_PAYLOAD}")"

    if [ "${STATUS_CODE}" -eq 201 ]; then
        log_info "The realm key provider '${REALM_KEY_PROVIDER_NAME}' has been set successfully."
    else
        log_error "Couldn't set the realm key provider '${REALM_KEY_PROVIDER_NAME}'. Failed with status code: ${STATUS_CODE}"
    fi
fi
}

config_saml(){
# Get idpSamlConfig.json file and perform variable substitution
SAML_PROVIDER_PAYLOAD="$(eval "cat <<EOF
$(<config-files/idpSamlConfig.json)
EOF
" 2>/dev/null)"

get_token
STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" \
    "${IDS_BASE_URL}/auth/admin/realms/${REALM}/identity-provider/instances" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    --data "${SAML_PROVIDER_PAYLOAD}")"

if [ "${STATUS_CODE}" -eq 201 ]; then
    log_info "The SAML Identity Provider '${IDP_ID}' has been created successfully."
elif [ "${STATUS_CODE}" -eq 409 ]; then
    log_info "The SAML Identity Provider '${IDP_ID}' already exists."
else
    log_error "Couldn't import SAML Identity Provider '${IDP_ID}'. Failed with status code: ${STATUS_CODE}"
fi
}

add_idp_mapper() {
    MAPPER_PAYLOAD="$(cat "config-files/${1}")"
    MAPPER_NAME="$(echo "${MAPPER_PAYLOAD}" | jq -r '.name')"

    log_info "Adding SAML mapper '${MAPPER_NAME}' ..."

    # Check if the requested saml mapper already exists
    get_token
    MAPPER_RESPONSE="$(curl -s "${IDS_BASE_URL}/auth/admin/realms/$REALM/identity-provider/instances/${IDP_ID}/mappers" \
        -H "Authorization: Bearer ${TOKEN}" | jq ".[] | select(.name==\"${MAPPER_NAME}\")")"

    if [ -n "${MAPPER_RESPONSE}" ]; then
        log_info "The mapper '${MAPPER_NAME}' already exists for ${IDP_ID} Provider."
    else
        # Add the saml mapper
        get_token
        STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" \
            "${IDS_BASE_URL}/auth/admin/realms/${REALM}/identity-provider/instances/${IDP_ID}/mappers" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            --data "${MAPPER_PAYLOAD}")"

        if [ "${STATUS_CODE}" -eq 201 ]; then
            log_info "The '${MAPPER_NAME}' mapper has been successfully added to the ${IDP_ID} Provider"
        else
            log_error "Couldn't add '${MAPPER_NAME}' mapper. Failed with status code: ${STATUS_CODE}"
        fi
    fi
}

enforce_saml()
{
log_info "Enforcing SAML flow execution ..."

# Get all executions for browser flow
get_token
EXECUTIONS="$(curl -s "${IDS_BASE_URL}/auth/admin/realms/${REALM}/authentication/flows/browser/executions" \
    -H "Authorization: Bearer ${TOKEN}")"

# Extract the id of "Identity Provider Redirector"
EXECUTION_ID="$(echo "${EXECUTIONS}" | jq .[] | jq -r 'select( .providerId == "identity-provider-redirector") | .id')"

# Extract the id of "Authentication Config"
AUTH_CFG_ID="$(echo "${EXECUTIONS}" | jq .[] | jq -r 'select( .providerId == "identity-provider-redirector") | .authenticationConfig')"


if [ "null" = "${AUTH_CFG_ID}" ]; then
    log_info "There is no authenticator config. Creating authenticator config ..."

    get_token
    STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" \
        "${IDS_BASE_URL}/auth/admin/realms/${REALM}/authentication/executions/${EXECUTION_ID}/config" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        -d @config-files/samlBrowserFlowExecution.json)"

    if [ "${STATUS_CODE}" -eq 201 ]; then
        log_info "The authenticator config has been created and the SAML flow execution is now enforced."
    else
        log_error "Couldn't create authenticator config and enforce SAML flow execution. Failed with status code: ${STATUS_CODE}"
    fi
else
    log_info "Updating the authenticator config ..."

    # Get the execution payload by inserting the ID of the identity-provider-redirector execution
    EXECUTION_PAYLOAD="$(cat config-files/samlBrowserFlowExecution.json | jq --arg id "${EXECUTION_ID}" '. + {id: $id}')"


    # Update execution of the SAML Identity Provider Redirector
    get_token
    STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" --request PUT \
        "${IDS_BASE_URL}/auth/admin/realms/${REALM}/authentication/config/${AUTH_CFG_ID}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        -d "${EXECUTION_PAYLOAD}")"

    if [ "${STATUS_CODE}" -eq 204 ]; then
        log_info "The authenticator config has been updated and SAML flow execution is now enforced."
    else
        log_error "Couldn't update enforce SAML flow execution. Failed with status code: ${STATUS_CODE}"
    fi
fi
}

## Set realm key
run_and_check_000_status_code configure_realm

## Import new SAML identity provider in Identity Service
run_and_check_000_status_code config_saml

## Adding SAML mappers
run_and_check_000_status_code "add_idp_mapper emailMapper.json"
run_and_check_000_status_code "add_idp_mapper firstNameMapper.json"
run_and_check_000_status_code "add_idp_mapper lastNameMapper.json"

## Enforce SAML authentication
enforce_saml

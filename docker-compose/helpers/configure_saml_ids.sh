#!/bin/bash

log_info() {
    echo "info::: $1"
}

log_error() {
    echo "error::: $1"
    exit 1
}

check_var() {
    if [ -z "$1" ]; then
        log_error "$2 env variable is mandatory"
    fi
}

# AIMS properties
IDP_ID='saml'
REALM='alfresco'
REALM_KEY_PROVIDER_NAME="${IDS_KEY_PROVIDER_NAME:-dbp-sso-rsa}"
SAML_CLIENT_ID="${AUTH0_CLIENT_ID}"

check_var "$HOST_IP" "HOST_IP"
check_var "$SAML_CLIENT_ID" "AUTH0_CLIENT_ID"

IDS_BASE_URL="http://${HOST_IP}:8999"

# Get the admin cli token
TOKEN=$(curl --insecure --silent --show-error "$IDS_BASE_URL/auth/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r ".access_token")

# Check if the realm key provider already exists
KEY_NAME=$(curl -s "$IDS_BASE_URL/auth/admin/realms/$REALM/components?parent=$REALM&type=org.keycloak.keys.KeyProvider&name=$REALM_KEY_PROVIDER_NAME" \
    -H "Authorization: Bearer $TOKEN" | jq '. | .[].name')

log_info "Setting the realm key provider '$REALM_KEY_PROVIDER_NAME' ..."

if [ -n "$KEY_NAME" ]; then
    log_info "The realm key provider '$REALM_KEY_PROVIDER_NAME' already exists."
else
    # Set the realm keys (i.e. private key and certificate. For example, the certificate that other party needs to validate the AIMS signed SAML message)
    KEYS_PAYLOAD=$(cat helpers/config-files/realmRsaKeys.json)
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IDS_BASE_URL/auth/admin/realms/$REALM/components" \
        --compressed \
        -H "Content-Type: application/json;charset=utf-8" \
        -H "Authorization: Bearer $TOKEN" \
        --data "$KEYS_PAYLOAD")

    if [ "$STATUS_CODE" = "201" ]; then
        log_info "The realm key provider '$REALM_KEY_PROVIDER_NAME' has been set successfully."
    else
        log_error "Couldn't set the realm key provider '$REALM_KEY_PROVIDER_NAME'. Failed with status code: $STATUS_CODE"
    fi
fi

# Get idpSamlConfig.json file and perform variable substitution
SAML_PROVIDER_PAYLOAD=$(eval "cat <<EOF
$(<helpers/config-files/idpSamlConfig.json)
EOF
" 2>/dev/null)

# Import new SAML identity provider in Identity Service
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IDS_BASE_URL/auth/admin/realms/$REALM/identity-provider/instances" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    --data "$SAML_PROVIDER_PAYLOAD")

if [ "$STATUS_CODE" = "201" ]; then
    log_info "The SAML Identity Provider '$IDP_ID' has been created successfully."
elif [ "$STATUS_CODE" = "409" ]; then
    log_info "The SAML Identity Provider '$IDP_ID' already exists."
else
    log_error "Couldn't import SAML Identity Provider '$IDP_ID'. Failed with status code: $STATUS_CODE"
fi

add_idp_mapper() {
    MAPPER_PAYLOAD=$(cat helpers/config-files/$1)
    MAPPER_NAME=$(echo "$MAPPER_PAYLOAD" | jq -r '.name')

    log_info "Adding SAML mapper '$MAPPER_NAME' ..."

    # Check if the requested saml mapper already exists
    MAPPER_RESPONSE=$(curl -s "$IDS_BASE_URL/auth/admin/realms/$REALM/identity-provider/instances/$IDP_ID/mappers" \
        -H "Authorization: Bearer $TOKEN" | jq ".[] | select(.name==\"$MAPPER_NAME\")")

    if [ -n "$MAPPER_RESPONSE" ]; then
        log_info "The mapper '$MAPPER_NAME' already exists for $IDP_ID Provider."
    else
        # Add the saml mapper
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IDS_BASE_URL/auth/admin/realms/$REALM/identity-provider/instances/$IDP_ID/mappers" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            --data "$MAPPER_PAYLOAD")

        if [ "$STATUS_CODE" = "201" ]; then
            log_info "The '$MAPPER_NAME' mapper has been successfully added to the $IDP_ID Provider"
        else
            log_error "Couldn't add '$MAPPER_NAME' mapper. Failed with status code: $STATUS_CODE"
        fi
    fi
}

# Adding SAML mappers
add_idp_mapper "emailMapper.json"
add_idp_mapper "firstNameMapper.json"
add_idp_mapper "lastNameMapper.json"

# Enforce SAML authentication
log_info "Enforcing SAML flow execution ..."

# Get all executions for browser flow
EXECUTIONS=$(curl -s "$IDS_BASE_URL/auth/admin/realms/$REALM/authentication/flows/browser/executions" \
    -H "Authorization: Bearer $TOKEN")

# Extract the id of "Identity Provider Redirector"
EXECUTION_ID=$(echo $EXECUTIONS | jq .[] | jq -r 'select( .providerId == "identity-provider-redirector") | .id')

# Extract the id of "Authentication Config"
AUTH_CFG_ID=$(echo $EXECUTIONS | jq .[] | jq -r 'select( .providerId == "identity-provider-redirector") | .authenticationConfig')

if [ "null" = "$AUTH_CFG_ID" ]; then
    log_info "There is no authenticator config. Creating authenticator config ..."

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$IDS_BASE_URL/auth/admin/realms/$REALM/authentication/executions/$EXECUTION_ID/config" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d @helpers/config-files/samlBrowserFlowExecution.json)

    if [ "$STATUS_CODE" = "201" ]; then
        log_info "The authenticator config has been created and the SAML flow execution is now enforced."
    else
        log_error "Couldn't create authenticator config and enforce SAML flow execution. Failed with status code: $STATUS_CODE"
    fi
else
    log_info "Updating the authenticator config ..."

    # Get the execution payload by inserting the ID of the identity-provider-redirector execution
    EXECUTION_PAYLOAD=$(cat helpers/config-files/samlBrowserFlowExecution.json | jq --arg id "$EXECUTION_ID" '. + {id: $id}')

    # Update execution of the SAML Identity Provider Redirector
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --request PUT "$IDS_BASE_URL/auth/admin/realms/$REALM/authentication/config/$AUTH_CFG_ID" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$EXECUTION_PAYLOAD")

    if [ "$STATUS_CODE" = "204" ]; then
        log_info "The authenticator config has been updated and SAML flow execution is now enforced."
    else
        log_error "Couldn't update enforce SAML flow execution. Failed with status code: $STATUS_CODE"
    fi

fi

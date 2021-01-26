#!/bin/bash

log_info() {
  echo "info::: ${1}"
}

log_error() {
  echo "error::: ${1}"
}

check_var() {
  if [ -z "${1}" ]; then
    log_error "${2} env variable is mandatory"
    exit 1
  fi
}

NAME="${2}"
IP="${2}"

check_var "${NAME}" "APP_NAME"
check_var "${IP}" "IDS_IP"

PAYLOAD="$(cat <<EOF
{
  "name": "${NAME}",
  "description": "Client for IDS testing",
  "oidc_conformant": true,
  "addons": {
     "samlp": {
       "mappings": {
         "username": "http://schemas.auth0.com/username",
         "email": "Email",
         "given_name": "FirstName",
         "family_name": "LastName"
       },
       "nameIdentifierProbes": [
         "http://schemas.auth0.com/username",
         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
       ],
       "logout": {
         "callback": "https://${IP}/auth/realms/alfresco/broker/saml/endpoint",
         "slo_enabled": true
       },
       "signingCert": "-----BEGIN CERTIFICATE-----\nMIIDKDCCAhACCQDOzewLMfhp2jANBgkqhkiG9w0BAQsFADBWMQswCQYDVQQGEwJH\nQjETMBEGA1UEBwwKTWFpZGVuaGVhZDERMA8GA1UECgwIQWxmcmVzY28xCzAJBgNV\nBAsMAlBTMRIwEAYDVQQDDAlsb2NhbGhvc3QwHhcNMTkwODE0MTExNzE1WhcNMjkw\nODE0MTExNzE1WjBWMQswCQYDVQQGEwJHQjETMBEGA1UEBwwKTWFpZGVuaGVhZDER\nMA8GA1UECgwIQWxmcmVzY28xCzAJBgNVBAsMAlBTMRIwEAYDVQQDDAlsb2NhbGhv\nc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDUj+s36XSWCVEitFod\nEDxNkrdT4IVF/000Ib8CzrcdlydV7kRi3+Op0e5sjnavPIAg0mLtPjbBZK8rieiy\nrVHLY0b0gPfRQUvpEU0rU7hgcGLREPWDho7n0XKXM75vEnaKog6ZsNiCAAISChzS\nH7yaxRabeai4fhFDsZibQN4GCnZil337JN+wFRgTMMNWiDEqmLx5MV9lWgDPYMs6\ni3fRC++ELAE9mbtUHugQmbRr3sS/E6sWE07RR70gzcUStEN4N+Q+p7rnRkHBNryO\n62pmyyr6qDbyu8FAteP8oV7XUKeRw7MU6vRCCf1LeNuBp1hn8MaISL96jneiFc+7\n2EhTAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAFQinkXktko9eoq0+wkeZWys2HRl\n6k6hkUNdun0qsvMN0bv3676+xWxL5iILO5BkIN9d2qV1Hupt82iBxWPyZaAIwOy2\nhDA+rMDrQBImDR4D+T9rGxFl3rIo5wHj6/yhgPQr+AAOnwHFoKzSLVSAMUjtUiKJ\nrg8cdkFIoxZhNApM+ytu8u6ekPPa/WQUwn5yheK/BsVqo8OgEj8YdT3sfb5aMVgC\nWIA2cEOjyzO5Nel+V7l7vXr2JZcwWuu42JMsqQJJjf8HRsGdcIgk8R2QVL/w1SYb\neU5w8+YjM/WRCmBvMkytoFQSdzxw8zu75mYm4cXJK9yYJoS/jflA9tb3mzc=\n-----END CERTIFICATE-----\n"
     }
  },
  "callbacks": [
    "https://${IP}/auth/realms/alfresco/broker/saml/endpoint"
  ],
  "app_type": "regular_web",
  "custom_login_page_on": true
}
EOF
)"

get_token() {
  curl -s https://dev-ps-alfresco.auth0.com/oauth/token \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "grant_type=client_credentials&client_id=${AUTH0_CLIENT_ID}&client_secret=${AUTH0_CLIENT_SECRET}&audience=https%3A%2F%2Fdev-ps-alfresco.auth0.com%2Fapi%2Fv2%2F" | jq -r ".access_token"
}

get_clientId() {
  TOKEN="$(get_token)"

  CLIENT_ID="$(curl -s "https://dev-ps-alfresco.auth0.com/api/v2/clients?fields=name,client_id" \
    -H "Authorization: Bearer ${TOKEN}" | jq .[] | jq -r "select(.name == \"${NAME}\") | .client_id")"
  echo "${CLIENT_ID}"
}

create_app() {
  TOKEN="$(get_token)"

  STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" "https://dev-ps-alfresco.auth0.com/api/v2/clients" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "$PAYLOAD")"

  if [ "$STATUS_CODE" = "201" ]; then
    log_info "The application '${NAME}' has been created successfully."
  else
    log_error "Couldn't create the application '${NAME}'. Failed with status code: ${STATUS_CODE}"
    exit 1
  fi
}

delete_app() {
  TOKEN="$(get_token)"

  CLIENT_ID="$(curl -s "https://dev-ps-alfresco.auth0.com/api/v2/clients?fields=name,client_id" \
    -H "Authorization: Bearer ${TOKEN}" |\
      jq .[] | jq -r "select(.name == \"${NAME}\") | .client_id")"

  log_info "Deleting application: '${NAME}' ..."

  STATUS_CODE="$(curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE "https://dev-ps-alfresco.auth0.com/api/v2/clients/${CLIENT_ID}" \
    -H "Authorization: Bearer ${TOKEN}")"

  if [ "${STATUS_CODE}" -eq 204 ]; then
    log_info "The application '${NAME}' has been deleted successfully."
  else
    log_error "Couldn't delete the application '${NAME}'. Failed with status code: ${STATUS_CODE}"
  fi
}

case "${1}" in
getId)
  get_clientId
  ;;
create)
  create_app
  ;;
delete)
  delete_app
  ;;
esac

exit 0

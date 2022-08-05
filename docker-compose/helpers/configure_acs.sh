#!/bin/bash
set -o errexit

# Util methods
log_info() {
  echo "info::: $1"
}

log_error() {
  echo "error::: $1"
  exit 1
}


echo "\n************************************"
log_info "Configuring ACS ..."
echo "************************************"

### Variables
BASE_URL="${HOST_IP:-http://localhost}:8080"
ADMIN_USERNAME="${ACS_ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ACS_ADMIN_PASSWORD:-admin}"
AUTH="$ADMIN_USERNAME:$ADMIN_PASSWORD"

log_info "Using ACS base URL: $BASE_URL"
log_info "Using Admin username: $ADMIN_USERNAME"

# Create the user
log_info "Creating user '$DEFAULT_USERNAME' in ACS ..."
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/alfresco/api/-default-/public/alfresco/versions/1/people" -u "$AUTH" \
  -H 'Content-Type: application/json' \
  -H 'cache-control: no-cache' \
  -d "{
  \"id\": \"$DEFAULT_USERNAME\",
  \"firstName\": \"$DEFAULT_FIRSTNAME\",
  \"lastName\": \"$DEFAULT_LASTNAME\",
  \"email\": \"$DEFAULT_EMAIL\",
  \"password\": \"$DEFAULT_PASSWORD\"
}")

if [ $STATUS_CODE -eq "201" ]; then
  log_info "The user '$DEFAULT_USERNAME' has been created successfully."
elif [ $STATUS_CODE -eq "409" ]; then
  log_info "The user '$DEFAULT_USERNAME' already exists."
else
  log_error "Couldn't create '$DEFAULT_USERNAME' user. Status code: $STATUS_CODE"
fi

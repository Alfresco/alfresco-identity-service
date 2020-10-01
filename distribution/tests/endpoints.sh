#!/bin/bash

log_info() {
  echo "info::: $1"
}

log_error() {
  echo "error::: $1"
  exit 1
}

TEST_NUM=0
log_test_passed() {
  TEST_NUM=$((TEST_NUM + 1))
  log_info "Test-$TEST_NUM: Passed."
}

WORK_DIR=$(pwd)

unzip -oq alfresco-identity-service-"$IDENTITY_VERSION".zip

PID=$(pgrep -f "standalone")
if [ -n "$PID" ]; then
  log_info "Killing existing process."
  pkill -KILL -f "standalone"
fi

cd alfresco-identity-service-$IDENTITY_VERSION/bin || exit

log_info "Starting the identity service"
/bin/bash -c './standalone.sh &'

SERVICEUP=0
# counters
COUNTER=0
# counters limit
COUNTER_MAX=60
# sleep seconds
SLEEP_SECONDS=1
while [ $SERVICEUP -eq 0 ] && [ "$COUNTER" -le "$COUNTER_MAX" ]; do
  log_info "Check identity service $COUNTER"
  response=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:8080/auth/)
  if [ "$response" -eq 200 ]; then
    SERVICEUP=1
    log_info "Identity service is up"
  else
    sleep "$SLEEP_SECONDS"
    COUNTER=$((COUNTER + 1))
  fi
done
[ $SERVICEUP -ne 1 ] && log_error "Identity Service timedout"

# Start the tests
echo ""
log_info "-------------------------------------------------------"
log_info " T E S T S "
log_info "-------------------------------------------------------"

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/auth/)
if [ $STATUS_CODE -ne "200" ]; then
  log_error "Invalid status code. Expected '200', but was '$STATUS_CODE'"
else
  log_test_passed
fi

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/auth/admin/alfresco/console/)
if [ $STATUS_CODE -ne "200" ]; then
  log_error "Invalid status code. Expected '200', but was '$STATUS_CODE'"
else
  log_test_passed
fi

RES=$(curl -sSL "http://localhost:8080/auth/realms/alfresco/account" | grep "Alfresco Identity Service")
if [ -z "$RES" ]; then
  log_error "Can't find application-name: 'Alfresco Identity Service'. Status code: : $STATUS_CODE"
else
  log_test_passed
fi

TOKEN=$(curl -ksS -d 'client_id=alfresco' -d 'username=admin' -d 'password=admin' -d 'grant_type=password' 'http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/token' | jq -r ".access_token")
if [ -z "$TOKEN" ]; then
  log_error "Couldn't get token'. Status code: : $STATUS_CODE"
else
  log_test_passed
fi

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:8080/auth/admin/realms)
if [ $STATUS_CODE -ne "200" ]; then
  log_error "Invalid status code. Expected '200', but was '$STATUS_CODE'"
else
  log_test_passed
fi

echo ""
log_info "Results:"
log_info "Tests run: $TEST_NUM, Passed: $TEST_NUM, Failures: 0"
log_info "-------------------------------------------------------"

echo ""
log_info "Starting cleanup..."

PID=$(pgrep -f "standalone" | tr '\n' ' ')
log_info "Killing identity service processes: $PID"
pkill -KILL -f "standalone"

cd "$WORK_DIR" || exit
log_info "Deleting alfresco-identity-service-$IDENTITY_VERSION directory."
rm -rf alfresco-identity-service-$IDENTITY_VERSION

log_info "Done."
exit 0

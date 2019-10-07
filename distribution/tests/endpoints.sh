#!/bin/bash

unzip alfresco-identity-service-$IDENTITY_VERSION.zip

EXISTENT_KEYCLOAK_INSTANCES=$(ps aux | grep "standalone" | awk '{print $2}' | head -n 2 )
echo $EXISTENT_KEYCLOAK_INSTANCES
kill $EXISTENT_KEYCLOAK_INSTANCES

cd alfresco-identity-service-$IDENTITY_VERSION/bin

echo "Starting the identity service"
/bin/bash -c './standalone.sh &'

SERVICEUP=0
 # counters
COUNTER=0
 # counters limit
COUNTER_MAX=60
 # sleep seconds
SLEEP_SECONDS=1
 while [ $SERVICEUP -eq 0 ] && [ "$COUNTER" -le "$COUNTER_MAX" ]; do
    echo "Check identity service $COUNTER"
    response=$(curl --write-out %{http_code} --silent --output /dev/null  http://localhost:8080/auth/)
    if [ $response -eq 200 ]; then
      SERVICEUP=1
      echo "Identity service is up"
    else
      sleep "$SLEEP_SECONDS"
      COUNTER=$((COUNTER + 1))
    fi
 done
[ $SERVICEUP -ne 1 ] && log_error "Identity Service timedout"

set -o errexit

curl -v http://localhost:8080/auth/
curl -v http://localhost:8080/auth/admin/alfresco/console/
curl -v "http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/auth?client_id=security-admin-console&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fauth%2Fadmin%2Falfresco%2Fconsole%2F&state=cd79cde9-02d2-4b9d-8299-870e638b7b6e&response_mode=fragment&response_type=code&scope=openid&nonce=fba6bbdb-27d4-49c1-8e7f-04fb4904fa5c" | grep "Alfresco Identity Service"
curl -v -d 'client_id=alfresco' -d 'username=admin' -d 'password=admin' -d 'grant_type=password' 'http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/token'

EXISTENT_KEYCLOAK_INSTANCES=$(ps aux | grep "standalone" | awk '{print $2}' | head -n 2 )
echo $EXISTENT_KEYCLOAK_INSTANCES
kill $EXISTENT_KEYCLOAK_INSTANCES

rm -rf alfresco-identity-service-$IDENTITY_VERSION

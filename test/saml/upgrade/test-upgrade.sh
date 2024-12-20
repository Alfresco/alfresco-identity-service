#!/bin/bash
# Description: This script will test Keycloak upgrade and JIT user provisioning (See JIRA tickets AUTH-529 and MNT-21741 for details)
# Author     : Jamal Kaabi-Mofrad
# Since      : IDS-1.5.0
#======================================================

source "../../distribution/build.properties"

. "../scripts/common.func"

pgrep_name="keycloak"

is_running() {
  RET=$(pgrep -f "$pgrep_name")
  if [ -n "$RET" ]; then
    return 0
  else
    return 1
  fi
}

stop_kc() {
  if ! is_running; then
    log_info "Keycloak is not running."
    exit 0
  else
    pkill -SIGINT -f "${pgrep_name}"

    STOPPED="0"
    KILL_MAX_SECONDS=10
    i=0
    log_info "Waiting at most ${KILL_MAX_SECONDS} seconds for regular termination of Keycloak."
    while [ "$i" -le "${KILL_MAX_SECONDS}" ]; do
      if is_running; then
        sleep 1
      else
        STOPPED="1"
        break
      fi
      i=$((i + 1))
    done

    if [ "$STOPPED" -ne "1" ]; then
      log_info "Regular shutdown of Keycloak server was not successful. Sending SIGKILL to process."
      pkill -KILL -f "${pgrep_name}"
      if is_running; then
        log_error_no_exit "Error stopping Keycloak."
      else
        log_info "Stopped Keycloak."
      fi
    else
      log_info "Stopped Keycloak."
    fi
  fi
}

# This is required if upgrading from a version of Keycloak which relies on h2 v1.x
migrate_h2_database() {
  wget https://repo1.maven.org/maven2/com/h2database/h2/2.3.230/h2-2.3.230.jar
  wget https://repo1.maven.org/maven2/com/h2database/h2/1.4.196/h2-1.4.196.jar
  dbdir="$(pwd)/${target}/data/h2"
  log_info "Exporting old h2 database to zip file..."
  java -cp h2-1.4.196.jar org.h2.tools.Script -url jdbc:h2:${dbdir}/keycloak -user sa -password sa -script h2db.zip -options compression zip
  rm -f ${target}/data/h2/keycloak.mv.db
  log_info "Creating new h2 database from zip file..."
  java -cp h2-2.3.230.jar org.h2.tools.RunScript -url jdbc:h2:${dbdir}/keycloakdb -user sa -password password -script ./h2db.zip -options compression zip FROM_1X
  rm -f h2db.zip
  rm -f $dbdir/keycloak.*
  log_info "h2 1.x -> 3.x migration successful!"
}

############################
#         Variables        #
############################

# /saml directory
current_dir=$(pwd)
workspace="${current_dir}/target/distribution/workspace"
# Keycloak doesn't send cookies for the cross origin request from the non secure context. Since we are using http in our
# tests we need to use loopback address which is considered as secure.
host_ip="127.0.0.1"
# Keycloak default port
port=8080
protocol="http"
base_url="${protocol}://${host_ip}:${port}"
app_name_prefix="local"
if [ -n "${KC_BUILD_NAME}" ]; then
  app_name_prefix="${KC_BUILD_NAME}"
fi
auth0_app_name="${app_name_prefix}-upgrade-to-${KEYCLOAK_VERSION}"

log_info "Building the current Keycloak version: ${KEYCLOAK_VERSION}"
make build -C ../../distribution

# Create a directory to copy the required Keycloak versions
mkdir -p "${workspace}"

from_version_zip=$(find target/distribution -name "alfresco-identity-service-*.zip")

# unzip the from version
log_info "Unzipping ${from_version_zip} ..."
unzip -oq -d "${workspace}" "$from_version_zip"

source=$(basename "${workspace}"/alfresco-identity-service-*)
source_version=$(echo "$source" | cut -d - -f4)
target="alfresco-keycloak-${KEYCLOAK_VERSION}"

##########################################
# Start the 'from' version and do a test #
##########################################

cd "${workspace}/${source}" || exit 1

# first add the admin user
log_info "Add the admin user ..."
bin/add-user-keycloak.sh -r master -u admin -p admin

log_info "Starting ${source} ..."
# Start the server in the background
kc_logfile=${current_dir}/from-kc-logfile
nohup ./bin/standalone.sh -b "${host_ip}" >"${kc_logfile}" 2>&1 &
# wait for the server to startup
sleep 20

cd "${current_dir}/../scripts" || exit 1

# Check the 'from' version
./check-keycloak-version.sh kc_base_url="${base_url}" kc_home="${workspace}/${source}"

# setup Auth0
log_info "Setup Auth0 ..."
./auth0-api.sh create "${auth0_app_name}" "${base_url}"

# Configure SAML
./configure-saml-kc.sh app_name="${auth0_app_name}" kc_base_url="${base_url}"

# cd to /saml dir
cd "${current_dir}" || exit 1
# Run the test
mvn -B -ntp test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}"
TESTS_RESULT=$?

if [[ "$TESTS_RESULT" -ne 0 ]] ; then
  log_error_no_exit "Tests against the 'from' version failed. Dumping Keycloak logs:"
  cat "${kc_logfile}"
fi

log_info "The tests have been completed. Stopping Keycloak..."
# Stop the 'from' version and do an upgrade
stop_kc

log_info "Upgrading from ${source} to ${target} ..."

log_info "Copy ${target} distro to workspace"
cp -r ../../distribution/"${target}" "${workspace}"

cd "${workspace}" || exit 1

log_info "Prepare the upgrade ..."

log_info "List of ${source} 'tx-object-store' before removal"
ls -lh "${source}"/standalone/data/tx-object-store

log_info "Remove ${source} tx-object-store ..."
rm -rf "${source}"/standalone/data/tx-object-store/*

log_info "List of ${source} tx-object-store after removal"
ls -lh "${source}"/standalone/data/tx-object-store

log_info "List all files of ${source}/standalone directory"
ls -lh "${source}"/standalone/

log_info "List all files of ${target}/data"
ls -lh "${target}"/data/

log_info "Copy db files within ${source}/standalone into ${target}/data/h2 directory"
mkdir -p "${target}"/data/h2 && cp -rf "${source}"/standalone/data/*.db "${target}"/data/h2/

# if the previous version of Keycloak relies on h2 v1.x, whereas the newer version requires v2.x
migrate_h2_database

log_info "List all files of ${target}/data/h2 directory after copy of old Keycloak"
ls -lh "${target}"/data/h2

cd "${target}" || exit 1

# Start the server in the background
kc_logfile=${current_dir}/to-kc-logfile
nohup bash bin/kc.sh start-dev --import-realm --http-relative-path="/auth" >"${kc_logfile}" 2>&1 &
# wait for the server to startup
sleep 20

cd "${current_dir}/../scripts" || exit 1

# Check the 'to' version
./check-keycloak-version.sh kc_base_url="${base_url}" kc_home="${workspace}/${target}"

# cd to /saml dir
cd "${current_dir}" || exit 1

# Run the test with the existing user. The user created in the first test run above
mvn -B -ntp test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}"
RETURN_CODE=$?
if [[ "$RETURN_CODE" -ne 0 ]] ; then
  TESTS_RESULT=$RETURN_CODE
fi

# Run the test with a new user. A user that does not exist in Keycloak yet
mvn -B -ntp test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}" -Dsaml.username=user2 -Dsaml.password=Passw0rd
RETURN_CODE=$?
if [[ "$RETURN_CODE" -ne 0 ]] ; then
  TESTS_RESULT=$RETURN_CODE
fi

log_info "The tests completed with the following aggregated exit code: ${TESTS_RESULT}"

if [[ "$TESTS_RESULT" -ne 0 ]] ; then
  log_error_no_exit "Tests against the 'to' version failed. Dumping Keycloak logs:"
  cat "${kc_logfile}"
fi

# Delete Auth0 application
cd "${current_dir}/../scripts" || exit 1

log_info "Cleanup ..."
log_info "Deleting Auth0 application: ${auth0_app_name} ..."
./auth0-api.sh delete "${auth0_app_name}"

exit $TESTS_RESULT

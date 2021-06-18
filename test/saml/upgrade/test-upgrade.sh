#!/bin/bash
# Description: This script will test IDS upgrade and JIT user provisioning (See JIRA tickets AUTH-529 and MNT-21741 for details)
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

stop_ids() {
  if ! is_running; then
    log_info "IDS server is not running."
    exit 0
  else
    pkill -SIGINT -f "${pgrep_name}"

    STOPPED="0"
    KILL_MAX_SECONDS=10
    i=0
    log_info "Waiting at most ${KILL_MAX_SECONDS} seconds for regular termination of IDS server."
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
      log_info "Regular shutdown of IDS server was not successful. Sending SIGKILL to process."
      pkill -KILL -f "${pgrep_name}"
      if is_running; then
        log_error_no_exit "Error stopping IDS."
      else
        log_info "Stopped IDS."
      fi
    else
      log_info "Stopped IDS."
    fi
  fi
}

# This is required if upgrading from a version less than 1.5.0 to a version greater than or equal to 1.5.0
# See https://www.keycloak.org/docs/13.0/upgrading/#migrating-to-13-0-0 for details
extra_migration_step() {
  compare_versions "$1" "1.5.0"
  case $? in
  0) op="=" ;;
  1) op=">" ;;
  2) op="<" ;;
  esac
  if [ "$op" = "<" ]; then
    compare_versions "1.5.0" "$IDENTITY_VERSION"
    case $? in
    0) op="=" ;;
    1) op=">" ;;
    2) op="<" ;;
    esac
    if [ "$op" != ">" ]; then
      log_info "Removing 'SmallRye' modules references from 'standalone.xml' file as you are upgrading to a version greater than or equal to 1.5.0"
    fi
  fi
  # If the upgrade going to be to >=1.5.0 then remove 'SmallRye' references
  sed '/smallrye/d' "${target}"/standalone/configuration/standalone.xml >standalone-temp.xml && mv standalone-temp.xml "${target}"/standalone/configuration/standalone.xml
}

############################
#         Variables        #
############################

# /saml directory
current_dir=$(pwd)
workspace="${current_dir}/target/distribution/workspace"
# Get the host IP
host_ip=$(ifconfig | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)
# Keycloak default port
port=8080
protocol="http"
base_url="${protocol}://${host_ip}:${port}"
app_name_prefix="local"
if [ -n "${IDS_BUILD_NAME}" ]; then
  app_name_prefix="${IDS_BUILD_NAME}"
fi
auth0_app_name="${app_name_prefix}-upgrade-to-${IDENTITY_VERSION}"

log_info "Building the current IDS version: ${IDENTITY_VERSION}"
make build -C ../../distribution

# Create a directory to copy the required IDS versions
mkdir -p "${workspace}"

from_version_zip=$(find target/distribution -name "alfresco-identity-service-*.zip")

# unzip the from version
log_info "Unzipping ${from_version_zip} ..."
unzip -oq -d "${workspace}" "$from_version_zip"

source=$(basename "${workspace}"/alfresco-identity-service-*)
source_version=$(echo "$source" | cut -d - -f4)
target="alfresco-identity-service-${IDENTITY_VERSION}"

##########################################
# Start the 'from' version and do a test #
##########################################

cd "${workspace}/${source}" || exit 1

# first add the admin user
log_info "Add the admin user ..."
bin/add-user-keycloak.sh -r master -u admin -p admin

log_info "Starting ${source} ..."
# Start the server in the background
nohup ./bin/standalone.sh -b "${host_ip}" >/dev/null 2>&1 &
# wait for the server to startup
sleep 20

cd "${current_dir}/../scripts" || exit 1

# Check the 'from' version
./check-keycloak-version.sh ids_base_url="${base_url}" ids_home="${workspace}/${source}"

# setup Auth0
log_info "Setup Auth0 ..."
./auth0-api.sh create "${auth0_app_name}" "${base_url}"

# Configure SAML
./configure-saml-ids.sh app_name="${auth0_app_name}" ids_base_url="${base_url}"

# cd to /saml dir
cd "${current_dir}" || exit 1
# Run the test
mvn test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}"

log_info "The test was successful. Stopping IDS server..."
# Stop the 'from' version and do an upgrade
stop_ids

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

log_info "List all files of ${target}/standalone"
ls -lh "${target}"/standalone/

log_info "Copy all files/dirs of ${source}/standalone into ${target}/standalone directory"
cp -rf "${source}"/standalone/* "${target}"/standalone/

# if the source is required to be upgraded to 1.5.0 or greater then perform additional steps
extra_migration_step "${source_version}"

log_info "List all files of ${target}/standalone directory after copy of old IDS"
ls -lh "${target}"/standalone/

cd "${target}" || exit 1

log_info "Executing the Standalone Mode Upgrade Script..."
bin/jboss-cli.sh --file=bin/migrate-standalone.cli

# Start the server in the background
nohup sh bin/standalone.sh -b "${host_ip}" >/dev/null 2>&1 &
# wait for the server to startup
sleep 20

cd "${current_dir}/../scripts" || exit 1

# Check the 'to' version
./check-keycloak-version.sh ids_base_url="${base_url}" ids_home="${workspace}/${target}"

# cd to /saml dir
cd "${current_dir}" || exit 1

# Run the test with the existing user. The user created in the first test run above
mvn test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}"

# Run the test with a new user. A user that does not exist in Keycloak yet
mvn test -Dkeycloak.protocol="${protocol}" -Dkeycloak.hostname="${host_ip}" -Dkeycloak.port="${port}" -Dsaml.username=user2 -Dsaml.password=Passw0rd

log_info "The tests were successful. Stopping IDS server..."
# Stop the 'to' version
stop_ids

# Delete Auth0 application
cd "${current_dir}/../scripts" || exit 1

log_info "Cleanup ..."
log_info "Deleting Auth0 application: ${auth0_app_name} ..."
./auth0-api.sh delete "${auth0_app_name}"

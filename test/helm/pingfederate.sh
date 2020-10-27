#!/bin/bash

. $(dirname $0)/common.func

PINGFEDERATE_API_URL=${PINGFEDERATE_API_URL:-"https://pingfederate.alfresco.me:9999/pf-admin-api/v1"}
XSRF_HEADER='X-XSRF-Header: PingFederate'
JSON_HEADER='Content-Type: application/json'
DEFAULT_CURL_OPTIONS="--silent --show-error"

VERBOSE=false
GET=false
CREATE=false
UPDATE=false
DELETE=false
FORCE=false
CONNECTION_ID=""
USER=""
PASSWORD=""
JSON_DATA_FILE=""

print_help() {
    cat << EOH
PingFederate SP connection management
Usage:
    $0 -g <connection id> -U <username> -P <password>
    $0 -c -U <username> -P <password> -j <JSON data file>
    $0 -u <connection id> -U <username> -P <password> -j <JSON data file>
    $0 -d <connection id> -U <username> -P <password> [-f]
Options:
    -U      PingFederate username with admin privileges
    -P      Password for PingFederate user
    -g      Get idp connection information for <connection id> (use empty string to get information all idP connections)
    -c      Create connection defined in <JSON data file>
    -u      Update <connection id>
    -j      Read json data from <JSON data file>
    -d      Delete <connection id>
    -f      Skip deletion confirmation prompt
Examples:
1. Get idp connection information for a specific connection
    $ $0 -U "<username>" -P "<password>" -g "y5llVocAX1EoeMHWy.UkV07AvSQ"
    {
      "type": "SP",
      "id": "y5llVocAX1EoeMHWy.UkV07AvSQ",
      "name": "kconkas.localhost",
      "entityId": "kconkas.localhost",
      "active": true,
      "contactInfo": {
        "company": "Alfresco",
        "email": "support@alfresco.com"
      },
      "baseUrl": "http://127.0.0.1:8080",
      "loggingMode": "STANDARD",
      "virtualEntityIds": [],
      "licenseConnectionGroup": "",
      "credentials": {
        "certs": [
      [ output cut ]
2. Create new connection (note: kc_local.json in this example has been created by exporting an existing connection and
   changing its parameters accordingly):
    $ $0 -U "<username>" -P "<password>" -c -j kc_local.json
    {
      "type": "SP",
      "id": "oHA8KbTBnF4KRYFkgDbxTDhhn2j",
      "name": "kconkas.localhost",
      "entityId": "kconkas.localhost",
      "active": true,
      "contactInfo": {
        "company": "Alfresco",
        "email": "support@alfresco.com"
      },
      "baseUrl": "http://127.0.0.1:8080",
      "loggingMode": "STANDARD",
     [ output cut ]
3. Modify a connection - example: make an idP connection inactive:
    a) get complete connection object
        $ ./pingfederate.sh -U "<username>" -P "<password>" -v -g "y5llVocAX1EoeMHWy.UkV07AvSQ" > kc_local.json
    b) modify exported connection object as required (in this example ""active": true," was changed to ""active": false,")
    c) update connection
        $ $0 -U "<username>" -P "<password>" -u "y5llVocAX1EoeMHWy.UkV07AvSQ" -j kc_local.json
        {
          "type": "SP",
          "id": "y5llVocAX1EoeMHWy.UkV07AvSQ",
          "name": "kconkas.localhost",
          "entityId": "kconkas.localhost",
          "active": false,
          "contactInfo": {
            "company": "Alfresco",
            "email": "support@alfresco.com"
          },
          [ output cut ]
4. Delete an idP connection (this operation is irrecoverable, use it with caution!):
    $ $0 -U "<username>" -P "<password>" -d "y5llVocAX1EoeMHWy.UkV07AvSQ"
    This will remove connection y5llVocAX1EoeMHWy.UkV07AvSQ, are you sure (yes/no)? yes
    info::: Deleting y5llVocAX1EoeMHWy.UkV07AvSQ ...
EOH
}

get_connection_info() {
    connection_id=$1
    $VERBOSE && log_info "Getting connection information for $connection_id ..."

    curl ${DEFAULT_CURL_OPTIONS} \
        -H "${XSRF_HEADER}" \
        -H "${JSON_HEADER}" \
        --user "${USER}:${PASSWORD}" \
        ${PINGFEDERATE_API_URL}/idp/spConnections/${connection_id} | jq '.'
}

create_connection() {
    json_file=$1

    $VERBOSE && log_info "Creating connection from JSON data file: ${json_file}"

    [ -z "${json_file}" ] && {
        log_error "create data file not specified"
    }

    curl ${DEFAULT_CURL_OPTIONS} \
        -XPOST \
        -H "${XSRF_HEADER}" \
        -H "${JSON_HEADER}" \
        --user "${USER}:${PASSWORD}" \
        ${PINGFEDERATE_API_URL}/idp/spConnections \
        --data "@${json_file}" | jq '.'
}


update_connection_info() {
    connection_id=$1
    json_file=$2

    $VERBOSE && {
        log_info "Updating connection information for ${connection_id} ..."
        log_info "JSON data file: ${json_file}"
    }

    [ -z "${json_file}" ] && {
        log_error "update data file not specified"
    }

    curl ${DEFAULT_CURL_OPTIONS} \
        -XPUT \
        -H "${XSRF_HEADER}" \
        -H "${JSON_HEADER}" \
        --user "${USER}:${PASSWORD}" \
        ${PINGFEDERATE_API_URL}/idp/spConnections/${connection_id} \
        --data "@${json_file}" | jq '.'
}

delete_connection() {
    connection_id=$1
    $VERBOSE && {
        log_info "Deleting ${connection_id} ..."
    }

    curl ${DEFAULT_CURL_OPTIONS} \
        -XDELETE \
        -H "${XSRF_HEADER}" \
        -H "${JSON_HEADER}" \
        --user "${USER}:${PASSWORD}" \
        ${PINGFEDERATE_API_URL}/idp/spConnections/${connection_id} | jq '.'
}

[ -z $(which jq) ] && {
    log_error "jq binary is missing or not in the PATH. This script won't work without it."
}

while getopts ":hvfcg:U:P:j:u:d:" opt; do
  case $opt in
    h)  print_help
        exit 0
        ;;

    v)  VERBOSE=true
        ;;

    U)  USER=$OPTARG
        ;;

    P)  PASSWORD=$OPTARG
        ;;

    j)  JSON_DATA_FILE=$OPTARG
        ;;

    g)  GET=true
        CONNECTION_ID=$OPTARG
        ;;

    u)  UPDATE=true
        CONNECTION_ID=$OPTARG
        ;;

    d)  DELETE=true
        CONNECTION_ID=$OPTARG
        ;;

    f)  FORCE=true
        ;;

    c)  CREATE=true
        ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

! ${GET} && ! ${CREATE} && ! ${UPDATE} && ! ${DELETE} && {
    echo "No parameters specified. Use \"$0 -h\" for usage instructions."
    exit 2
}

if [ -z "${USER}" -o -z "${PASSWORD}" ]
then
    echo "Username and password must be specified"
    exit 3
fi

if ${GET}; then
    get_connection_info ${CONNECTION_ID}

elif ${CREATE}; then
    create_connection ${JSON_DATA_FILE}

elif ${UPDATE}; then
    update_connection_info ${CONNECTION_ID} ${JSON_DATA_FILE}

elif ${DELETE}; then
    [ -z "${CONNECTION_ID}" ] && log_error "Connection ID is mandatory"

    ${FORCE} || {
        printf "This will remove connection $CONNECTION_ID, are you sure (yes/no)? "
        read answer

        if [ "${answer}" != "yes" ]; then
            echo "Delete aborted"
            exit 1
        fi
    }

    TMPFILE=/tmp/pfd.$$

    # make connection inactive, this is required in order to be able to delete it
    get_connection_info ${CONNECTION_ID} | egrep -v '\w+:::' | jq '.active=false' > $TMPFILE || \
        log_error "Unable to get connection information for $CONNECTION_ID"
    res=$(update_connection_info ${CONNECTION_ID} ${TMPFILE} | egrep -v '\w+:::' | jq '.active')
    [ "${res}" = "false" ] || {
        log_error "Unable to set connection $CONNECTION_ID inactive"
    }

    delete_connection ${CONNECTION_ID}
fi
#!/bin/bash

#  waits for a particular log to be found inside a docker service until MAX_TRIES minutes is reached
#  example:
#  $ ./wait-for-container-log.sh "alfresco" "Starting ProtocolHandler"

# Util methods
log_info() {
  echo "info::: $1"
}

log_error() {
  echo "error::: $1"
  exit 1
}

MAX_TRIES=100

waitUntil() {
  attempt=1
  while [ $attempt -le $MAX_TRIES ]; do
    if "$@"; then
      log_info "$@ passed!"
      break
    fi
    log_info "Waiting for $1... (attempt: $((attempt++)))"
    sleep 10
  done

  if [ $attempt -gt $MAX_TRIES ]; then
    log_error "Error on waiting until [$1] . Cancelling set up after $MAX_TRIES seconds"
  fi
}

# receives 2 arguments:
# 1 - container services name
# 2 - log that tells us container is ready
containerIsReady() {
  container=$1
  shift
  log_in_container=$@

  log_info "Listening on container: [$container] for log: [$log_in_container]"
  docker-compose logs $container | grep "$log_in_container"
}

waitUntil containerIsReady $1 $2

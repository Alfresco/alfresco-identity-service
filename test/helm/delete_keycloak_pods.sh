#!/usr/bin/env bash
set -e

. "test/scripts/common.func"

namespace=$(get_namespace)

# space separated list of pod names
delete_pod "keycloak kc-k" $namespace

wait_for_all_pod_readiness

wait_for_url_200_status "https://$HOST/auth/realms/master"

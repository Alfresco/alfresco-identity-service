#!/bin/bash

export STAGE_SUFFIX=$(echo ${TRAVIS_BUILD_STAGE_NAME} | tr -d . | awk '{print tolower($0)}')
export namespace=$(echo ${TRAVIS_BRANCH} | cut -c1-28 | tr /_ - | tr -d [:punct:] | awk '{print tolower($0)}')-${TRAVIS_BUILD_NUMBER}-${STAGE_SUFFIX}
export release_name_ingress=ing-${TRAVIS_BUILD_NUMBER}-${STAGE_SUFFIX}
export release_name_ids=ids-${TRAVIS_BUILD_NUMBER}-${STAGE_SUFFIX}
# export values_file=helm/alfresco-content-services/values.yaml

# if [[ ${TRAVIS_BUILD_STAGE_NAME} != "test" ]]; then
#     values_file="helm/alfresco-content-services/${TRAVIS_BUILD_STAGE_NAME}_values.yaml"
# fi

# deploy=false

# if [[ "${TRAVIS_COMMIT_MESSAGE}" == *"[run all tests]"* ]] || [[ "${GIT_DIFF}" == *helm/alfresco-content-services/${TRAVIS_BUILD_STAGE_NAME}_values.yaml* ]] || [[ "${GIT_DIFF}" == *helm/alfresco-content-services/templates* ]] || [[ "${GIT_DIFF}" == *helm/alfresco-content-services/charts* ]] || [[ "${GIT_DIFF}" == *helm/alfresco-content-services/requirements* ]] || [[ "${GIT_DIFF}" == *helm/alfresco-content-services/values.yaml* ]] || [[ "${GIT_DIFF}" == *test/postman/helm* ]]
# then
#     deploy=true
# fi

# if $deploy; then
# Utility Functions

# pod status
pod_status() {
    kubectl get pods --namespace $namespace -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?\(@.type==\'Ready\'\)].status
}

# pods ready
pods_ready() {
    PODS_COUNTER=0
    PODS_COUNTER_MAX=60
    PODS_SLEEP_SECONDS=10

    while [ "$PODS_COUNTER" -lt "$PODS_COUNTER_MAX" ]; do
    totalpods=$(pod_status | grep -v NAME | wc -l | sed 's/ *//')
    readypodcount=$(pod_status | grep ' True' | wc -l | sed 's/ *//')
    if [ "$readypodcount" -eq "$totalpods" ]; then
            echo "     $readypodcount/$totalpods pods ready now"
            pod_status
        echo "All pods are ready!"
        break
    fi
        PODS_COUNTER=$((PODS_COUNTER + 1))
        echo "just $readypodcount/$totalpods pods ready now - sleeping $PODS_SLEEP_SECONDS seconds - counter $PODS_COUNTER"
        sleep "$PODS_SLEEP_SECONDS"
        continue
    done

    if [ "$PODS_COUNTER" -ge "$PODS_COUNTER_MAX" ]; then
    pod_status
    echo "Pods did not start - exit 1"
    exit 1
    fi
}

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    name: $namespace:psp
    namespace: $namespace
rules:
- apiGroups:
    - policy
    resourceNames:
    - kube-system
    resources:
    - podsecuritypolicies
    verbs:
    - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: $namespace:psp:default
    namespace: $namespace
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: $namespace:psp
subjects:
- kind: ServiceAccount
    name: default
    namespace: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: $namespace:psp:$release_name_ingress-nginx-ingress
    namespace: $namespace
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: $namespace:psp
subjects:
- kind: ServiceAccount
    name: $release_name_ingress-nginx-ingress
    namespace: $namespace
---
$(kubectl create secret docker-registry quay-registry-secret --dry-run=client --docker-server=${DOCKER_REGISTRY} --docker-username=${DOCKER_REGISTRY_USERNAME} --docker-password=${DOCKER_REGISTRY_PASSWORD} -n $namespace -o yaml)
EOF

# install ingress
helm upgrade --install $release_name_ingress stable/nginx-ingress \
--set controller.scope.enabled=true \
--set controller.scope.namespace=$namespace \
--set rbac.create=true \
--set controller.config."proxy-body-size"="100m" \
--set controller.service.targetPorts.https=80 \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"="http" \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"="https" \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="${ACM_CERTIFICATE}" \
--set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"="$namespace.dev.alfresco.me" \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-negotiation-policy"="ELBSecurityPolicy-TLS-1-2-2017-01" \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-security-groups"="${AWS_SG}" \
--set controller.publishService.enabled=true \
--wait \
--atomic \
--namespace $namespace

# install acs
# helm dep up helm/alfresco-content-services
# travis_wait 25 helm upgrade --install $release_name_ids helm/alfresco-content-services \
# --values=$values_file \
# --set externalPort="443" \
# --set externalProtocol="https" \
# --set externalHost="$namespace.dev.alfresco.me" \
# --set persistence.enabled=true \
# --set persistence.storageClass.enabled=true \
# --set persistence.storageClass.name="nfs-client" \
# --set global.alfrescoRegistryPullSecrets=quay-registry-secret \
# --wait \
# --timeout 20m0s \
# --atomic \
# --namespace=$namespace

# install identity service
helm dep up helm/alfresco-identity-service
helm upgrade --install $release_name_ids helm/alfresco-identity-service \
    --values "${PWD}/.travis/test-values.yaml" \
    --set ingressHostName=$namespace.dev.alfresco.me \
    --set realm.alfresco.client.redirectUris={http://alfresco-identity-service.$namespace.dev.alfresco.me*,https://alfresco-identity-service.$namespace.dev.alfresco.me*} \
    --namespace=$namespace

# check dns and pods
DNS_PROPAGATED=0
DNS_COUNTER=0
DNS_COUNTER_MAX=90
DNS_SLEEP_SECONDS=10

echo "Trying to perform a trace DNS query to prevent caching"
dig +trace $namespace.dev.alfresco.me @8.8.8.8

while [ "$DNS_PROPAGATED" -eq 0 ] && [ "$DNS_COUNTER" -le "$DNS_COUNTER_MAX" ]; do
    host $namespace.dev.alfresco.me 8.8.8.8
    if [ "$?" -eq 1 ]; then
    DNS_COUNTER=$((DNS_COUNTER + 1))
    echo "DNS Not Propagated - Sleeping $DNS_SLEEP_SECONDS seconds"
    sleep "$DNS_SLEEP_SECONDS"
    else
    echo "DNS Propagated"
    DNS_PROPAGATED=1
    fi
done

[ $DNS_PROPAGATED -ne 1 ] && echo "DNS entry for $namespace.dev.alfresco.me did not propagate within expected time" && exit 1

pods_ready

# Delay running the tests to give ingress & SOLR a chance to fully initialise
echo "Waiting 2 minutes from $(date) before running tests..."
sleep 120

# run acs checks
# docker run -a STDOUT --volume $PWD/test/postman/helm:/etc/newman --network host postman/newman_alpine33:3.9.2 run "acs-test-helm-collection.json" --global-var "protocol=https" --global-var "url=$namespace.dev.alfresco.me"
# TEST_RESULT=$?
# echo "TEST_RESULT=${TEST_RESULT}"
# if [[ "${TEST_RESULT}" == "0" ]]; then
#     TEST_RESULT=0
#     # run sync service checks
#     if [[ "$values_file" != "helm/alfresco-content-services/6.0.N_values.yaml" ]] && [[ "$values_file" != "helm/alfresco-content-services/community_values.yaml" ]]; then
#     docker run -a STDOUT --volume $PWD/test/postman/helm:/etc/newman --network host postman/newman_alpine33:3.9.2 run "sync-service-test-helm-collection.json" --global-var "protocol=https" --global-var "url=$namespace.dev.alfresco.me"
#     TEST_RESULT=$?
#     echo "TEST_RESULT=${TEST_RESULT}"
#     fi

#     if [[ "${TEST_RESULT}" == "0" ]]; then
#     # For checking if persistence failover is correctly working with our deployments
#     # in the next phase we delete the acs and postgress pods,
#     # wait for k8s to recreate them, then check if the data created in the first test run is still there
#     kubectl delete pod -l app=$release_name_ids-alfresco-cs-repository,component=repository -n $namespace
#     kubectl delete pod -l app=postgresql-acs,release=$release_name_ids -n $namespace
#     helm upgrade $release_name_ids helm/alfresco-content-services \
#     --wait \
#     --timeout 10m0s \
#     --atomic \
#     --reuse-values \
#     --namespace=$namespace

#     # check pods
#     pods_ready

#     # run checks after pod deletion
#     docker run -a STDOUT --volume $PWD/test/postman/helm:/etc/newman --network host postman/newman_alpine33:3.9.2 run "acs-validate-volume-collection.json" --global-var "protocol=https" --global-var "url=$namespace.dev.alfresco.me"
#     TEST_RESULT=$?
#     echo "TEST_RESULT=${TEST_RESULT}"
#     fi
# fi

if [[ "$TRAVIS_COMMIT_MESSAGE" != *"[keep env]"* ]]; then
    helm delete $release_name_ingress $release_name_ids -n $namespace
    kubectl delete namespace $namespace
fi

# if [[ "${TEST_RESULT}" == "1" ]]; then
#     echo "Tests failed, exiting"
#     exit 1
# fi

# fi
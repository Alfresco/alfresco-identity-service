#!/bin/bash

set -o errexit

declare -r currentDir="$(dirname "${BASH_SOURCE[0]}")"
source "${currentDir}/build.properties"

CHART_DIR="${currentDir}/../helm/alfresco-identity-service"
HELM_REPO_NAME="identity-test"

echo "Downloading keycloak"
curl --silent --show-error -O https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip

echo "unzipping keycloak"
unzip -oq keycloak-$KEYCLOAK_VERSION.zip

echo "generating realm from template"
mkdir -p keycloak-$KEYCLOAK_VERSION/realm

helm init --client-only
if [ -z "$(helm repo list | grep ${HELM_REPO_NAME})" ]
then
    echo "adding helm repository"
    helm repo add ${HELM_REPO_NAME} ${bamboo_helm_repo_location}
fi

#
# Alfresco realm template is stored in ../helm/alfresco-identity-service/alfresco-realm.json. It isn't a valid JSON
# file and is also missing the corresponding "values.yaml" values. In order to generate a valid realm file, it must be
# rendered (without installation) using helm. Note only "realm-secret.yaml" needs to be rendered as this is how the
# realm gets passed on to keycloak when on k8s.
#
helm repo update
helm dependency update ${CHART_DIR}
helm template ${CHART_DIR} \
    -f ${CHART_DIR}/values.yaml \
    -x templates/realm-secret.yaml \
    --set realm.alfresco.client.redirectUris='{*}' | \
    grep  '\"alfresco-realm.json\"' | awk '{ print $2}' | \
    sed -e 's/\"$//' -e 's/^\"//' | base64 --decode | jq '.' > keycloak-$KEYCLOAK_VERSION/realm/alfresco-realm.json

cp -rf README.html keycloak-$KEYCLOAK_VERSION/

echo "adding themes"

docker run --rm -v "$PWD/alfresco:/tmp" alfresco/alfresco-keycloak-theme:$THEME_VERSION sh -c "rm -rf /tmp/* && cp -rf /alfresco/* /tmp/"
cp -rf alfresco keycloak-$KEYCLOAK_VERSION/themes/

echo '# Alfresco realm import ' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf
echo 'JAVA_OPTS="$JAVA_OPTS -Dkeycloak.import=../realm/alfresco-realm.json"' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf

echo 'rem # Alfresco realm import ' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.bat
echo "set \"JAVA_OPTS=%JAVA_OPTS% -Dkeycloak.import=%~dp0..\\\realm\\\alfresco-realm.json\"\n:JAVA_OPTS_SET" >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.bat

echo '# Alfresco realm import ' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.ps1
echo "\$JAVA_OPTS += \"-Dkeycloak.import=\$pwd\\\..\\\realm\\\alfresco-realm.json\"" >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.ps1

rm -f keycloak-$KEYCLOAK_VERSION/themes/keycloak/common/resources/node_modules/rcue/dist/img/git-Logo.svg
rm -rf alfresco-identity-service-$IDENTITY_VERSION
mkdir alfresco-identity-service-$IDENTITY_VERSION
cp -rf keycloak-$KEYCLOAK_VERSION/* alfresco-identity-service-$IDENTITY_VERSION/
rm -rf keycloak-$KEYCLOAK_VERSION
ls alfresco-identity-service-$IDENTITY_VERSION

echo packaging identity
zip -r alfresco-identity-service-$IDENTITY_VERSION.zip alfresco-identity-service-$IDENTITY_VERSION
openssl md5 -binary alfresco-identity-service-$IDENTITY_VERSION.zip > alfresco-identity-service-$IDENTITY_VERSION.md5
#!/bin/bash
set -o errexit

declare -r currentDir="$(dirname "${BASH_SOURCE[0]}")"
source "${currentDir}/build.properties"

ARGS=$@
for arg in $ARGS; do
  eval "$arg"
done

CHART_DIR="${currentDir}/../helm/alfresco-keycloak"

KEYCLOAK_NAME=keycloak-$KEYCLOAK_VERSION
KEYCLOAK_DISTRO=$KEYCLOAK_NAME.zip
DISTRIBUTION_NAME=alfresco-keycloak-$KEYCLOAK_VERSION

THEME_VERSION="${THEME_VERSION:-$theme_version}"

echo "Downloading $KEYCLOAK_NAME"
curl -sSLO https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/$KEYCLOAK_DISTRO

echo "Unzipping Keycloak"
unzip -oq $KEYCLOAK_DISTRO

echo "Copy Keycloak files into $DISTRIBUTION_NAME"
rm -f $KEYCLOAK_NAME/themes/keycloak/common/resources/node_modules/rcue/dist/img/git-Logo.svg
rm -rf $DISTRIBUTION_NAME
mkdir -p $DISTRIBUTION_NAME
cp -rf $KEYCLOAK_NAME/* $DISTRIBUTION_NAME/
rm -rf $KEYCLOAK_NAME
rm -rf $KEYCLOAK_DISTRO
rm -f $DISTRIBUTION_NAME.zip
rm -f $DISTRIBUTION_NAME.md5

#############################
# Configure AIMS zip distro #
#############################
echo "#########################################################################"
echo "# Building and configuring 'alfresco-identity-service' distribution zip #"
echo "#########################################################################"

echo "Generating realm from template"
mkdir -p $DISTRIBUTION_NAME/realm

#
# Alfresco realm template is stored in ../helm/alfresco-keycloak/alfresco-realm.json. It isn't a valid JSON
# file and is also missing the corresponding "values.yaml" values. In order to generate a valid realm file, it must be
# rendered (without installation) using helm. Note only "realm-secret.yaml" needs to be rendered as this is how the
# realm gets passed on to keycloak when on k8s.
#
helm repo add stable https://charts.helm.sh/stable
helm repo add codecentric https://codecentric.github.io/helm-charts

helm repo update
helm dependency update ${CHART_DIR}
mkdir -p $DISTRIBUTION_NAME/data/import
helm template ${CHART_DIR} \
  -f ${CHART_DIR}/values.yaml \
  --show-only templates/realm-secret.yaml \
  --set realm.alfresco.client.redirectUris='{*}' |
  grep '\"alfresco-realm.json\"' | awk '{ print $2}' |
  sed -e 's/\"$//' -e 's/^\"//' | base64 --decode | jq '.' >$DISTRIBUTION_NAME/data/import/alfresco-realm.json

echo "Recreate Distro Readme file"
cp -rf README.html $DISTRIBUTION_NAME/
sed -ie "s/KVERSION/$KEYCLOAK_VERSION/" $DISTRIBUTION_NAME/README.html

# zip the configured distro
zip -rq $DISTRIBUTION_NAME.zip $DISTRIBUTION_NAME
openssl md5 $DISTRIBUTION_NAME.zip >$DISTRIBUTION_NAME.md5

ls -la

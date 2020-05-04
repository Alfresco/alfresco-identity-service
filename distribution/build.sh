#!/bin/bash
set -o errexit

declare -r currentDir="$(dirname "${BASH_SOURCE[0]}")"
source "${currentDir}/build.properties"

CHART_DIR="${currentDir}/../helm/alfresco-identity-service"

HELM_REPO_NAME="alfresco-incubator"
KEYCLOAK_NAME=keycloak-$KEYCLOAK_VERSION
KEYCLOAK_DISTRO=$KEYCLOAK_NAME.zip
DISTRIBUTION_NAME=alfresco-identity-service-$IDENTITY_VERSION

if [ "$bamboo_helm_repo_location" == "" ]; then
    bamboo_helm_repo_location=https://kubernetes-charts.alfresco.com/incubator
fi

echo "Downloading $KEYCLOAK_NAME"

curl -sSLO https://github.com/Alfresco/keycloak/releases/download/$KEYCLOAK_VERSION/$KEYCLOAK_DISTRO

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
# Alfresco realm template is stored in ../helm/alfresco-identity-service/alfresco-realm.json. It isn't a valid JSON
# file and is also missing the corresponding "values.yaml" values. In order to generate a valid realm file, it must be
# rendered (without installation) using helm. Note only "realm-secret.yaml" needs to be rendered as this is how the
# realm gets passed on to keycloak when on k8s.
#
helm init --client-only
if [ -z "$(helm repo list | grep ${HELM_REPO_NAME})" ]
then
    echo "adding helm repository"
    helm repo add ${HELM_REPO_NAME} ${bamboo_helm_repo_location}
fi
helm repo add codecentric https://codecentric.github.io/helm-charts

helm repo update
helm dependency update ${CHART_DIR}
helm template ${CHART_DIR} \
    -f ${CHART_DIR}/values.yaml \
    -x templates/realm-secret.yaml \
    --set realm.alfresco.client.redirectUris='{*}' | \
    grep  '\"alfresco-realm.json\"' | awk '{ print $2}' | \
    sed -e 's/\"$//' -e 's/^\"//' | base64 --decode | jq '.' > $DISTRIBUTION_NAME/realm/alfresco-realm.json

echo "Recreate Distro Readme file"
cp -rf README.html $DISTRIBUTION_NAME/
sed -ie "s/IDVERSION/$IDENTITY_VERSION/" $DISTRIBUTION_NAME/README.html
sed -ie "s/KVERSION/$KEYCLOAK_VERSION/" $DISTRIBUTION_NAME/README.html

# unix settings
echo '# Alfresco realm import ' >> $DISTRIBUTION_NAME/bin/standalone.conf
echo 'JAVA_OPTS="$JAVA_OPTS -Dkeycloak.import=$JBOSS_HOME/realm/alfresco-realm.json"' >> $DISTRIBUTION_NAME/bin/standalone.conf

# windows settings
echo 'rem # Alfresco realm import ' >> $DISTRIBUTION_NAME/bin/standalone.conf.bat
echo -e "set \"JAVA_OPTS=%JAVA_OPTS% -Dkeycloak.import=%~dp0..\\\realm\\\alfresco-realm.json\"\n:JAVA_OPTS_SET" >> $DISTRIBUTION_NAME/bin/standalone.conf.bat

echo '# Alfresco realm import ' >> $DISTRIBUTION_NAME/bin/standalone.conf.ps1
echo "\$JAVA_OPTS += \"-Dkeycloak.import=\$pwd\\\..\\\realm\\\alfresco-realm.json\"" >> $DISTRIBUTION_NAME/bin/standalone.conf.ps1

# zip the confiured distro
zip -rq $DISTRIBUTION_NAME.zip $DISTRIBUTION_NAME
openssl md5 $DISTRIBUTION_NAME.zip > $DISTRIBUTION_NAME.md5

ls -la

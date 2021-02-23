#!/bin/bash
set -o errexit

declare -r currentDir="$(dirname "${BASH_SOURCE[0]}")"
source "${currentDir}/build.properties"

ARGS=$@
for arg in $ARGS; do
  eval "$arg"
done

CHART_DIR="${currentDir}/../helm/alfresco-identity-service"

HELM_REPO_NAME="alfresco-incubator"
KEYCLOAK_NAME=keycloak-$KEYCLOAK_VERSION
KEYCLOAK_DISTRO=$KEYCLOAK_NAME.zip
DISTRIBUTION_NAME=alfresco-identity-service-$IDENTITY_VERSION

# Dev variables
KEYCLOAK_GIT_REPO="${KEYCLOAK_GIT_REPO:-$keycloak_git_repo}"
KEYCLOAK_GIT_BRANCH="${KEYCLOAK_GIT_BRANCH:-$keycloak_git_branch}"
THEME_VERSION="${THEME_VERSION:-$theme_version}"

HELM_REPO_LOCATION="${HELM_REPO_LOCATION:-https://kubernetes-charts.alfresco.com/incubator}"

if [ "$KEYCLOAK_GIT_REPO" != "" ]; then
  if [ "$KEYCLOAK_GIT_BRANCH" == "" ]; then
    KEYCLOAK_GIT_BRANCH="master"
  fi

  mkdir -p temp
  cd temp
  echo "Building Git branch: $KEYCLOAK_GIT_BRANCH"
  # Clone repository
  git clone --depth 1 https://github.com/"$KEYCLOAK_GIT_REPO".git -b "$KEYCLOAK_GIT_BRANCH" keycloak-source

  # Build
  cd keycloak-source

  echo "Get keycloak version from the project pom.xml"
  VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
  echo "Using keycloak version: $VERSION"
  # Override variables
  KEYCLOAK_NAME=keycloak-$VERSION
  KEYCLOAK_DISTRO=$KEYCLOAK_NAME.zip

  MASTER_HEAD=$(git log -n1 --format="%H")
  echo "Build Keycloak from: $KEYCLOAK_GIT_REPO/$KEYCLOAK_GIT_BRANCH/commit/$MASTER_HEAD"

  mvn -Pdistribution -pl distribution/server-dist -am -Dmaven.test.skip clean install
  # Add Alfresco theme
  export THEME_VERSION="$THEME_VERSION"
  ./add-alfresco-theme.sh

  mv distribution/server-dist/target/keycloak-*.zip ../../$KEYCLOAK_DISTRO
  cd ../..
  rm -rf temp
else
  echo "Downloading $KEYCLOAK_NAME"
  curl -sSLO https://github.com/Alfresco/keycloak/releases/download/$KEYCLOAK_VERSION/$KEYCLOAK_DISTRO
fi

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
helm repo add stable https://charts.helm.sh/stable --force-update
if [ -z "$(helm repo list | grep ${HELM_REPO_NAME})" ]; then
  echo "adding helm repository"
  helm repo add ${HELM_REPO_NAME} "${HELM_REPO_LOCATION}"
fi
helm repo add codecentric https://codecentric.github.io/helm-charts

helm repo update
helm dependency update ${CHART_DIR}
helm template ${CHART_DIR} \
  -f ${CHART_DIR}/values.yaml \
  --show-only templates/realm-secret.yaml \
  --set realm.alfresco.client.redirectUris='{*}' |
  grep '\"alfresco-realm.json\"' | awk '{ print $2}' |
  sed -e 's/\"$//' -e 's/^\"//' | base64 --decode | jq '.' >$DISTRIBUTION_NAME/realm/alfresco-realm.json

echo "Recreate Distro Readme file"
cp -rf README.html $DISTRIBUTION_NAME/
sed -ie "s/IDVERSION/$IDENTITY_VERSION/" $DISTRIBUTION_NAME/README.html
sed -ie "s/KVERSION/$KEYCLOAK_VERSION/" $DISTRIBUTION_NAME/README.html

# unix settings
echo '# Alfresco realm import ' >>$DISTRIBUTION_NAME/bin/standalone.conf
echo 'JAVA_OPTS="$JAVA_OPTS -Dkeycloak.import=$JBOSS_HOME/realm/alfresco-realm.json"' >>$DISTRIBUTION_NAME/bin/standalone.conf

# windows settings
echo 'rem # Alfresco realm import ' >>$DISTRIBUTION_NAME/bin/standalone.conf.bat
echo -e "set \"JAVA_OPTS=%JAVA_OPTS% -Dkeycloak.import=%~dp0..\\\realm\\\alfresco-realm.json\"\n:JAVA_OPTS_SET" >>$DISTRIBUTION_NAME/bin/standalone.conf.bat

echo '# Alfresco realm import ' >>$DISTRIBUTION_NAME/bin/standalone.conf.ps1
echo "\$JAVA_OPTS += \"-Dkeycloak.import=\$pwd\\\..\\\realm\\\alfresco-realm.json\"" >>$DISTRIBUTION_NAME/bin/standalone.conf.ps1

# zip the configured distro
zip -rq $DISTRIBUTION_NAME.zip $DISTRIBUTION_NAME
openssl md5 $DISTRIBUTION_NAME.zip >$DISTRIBUTION_NAME.md5

ls -la

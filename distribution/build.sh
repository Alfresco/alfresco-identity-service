#!/bin/bash

set -o errexit

declare -r here="$(dirname "${BASH_SOURCE[0]}")"
source "${here}/build.properties"

echo "Downloading keycloak"
curl -O https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip

echo "unzipping keycloak"
unzip -oq keycloak-$KEYCLOAK_VERSION.zip

echo "adding realm"
mkdir -p keycloak-$KEYCLOAK_VERSION/realm
cp ../helm/alfresco-identity-service/alfresco-realm.json keycloak-$KEYCLOAK_VERSION/realm/
sed -i'.bak' "
  s#ALFRESCO_CLIENT_REDIRECT_URIS#[\"*\"]#g;
" keycloak-$KEYCLOAK_VERSION/realm/alfresco-realm.json

echo "adding themes"
rm -rf alfresco
mkdir alfresco
docker run --rm -v "$PWD/alfresco:/tmp" alfresco/alfresco-keycloak-theme:$THEME_VERSION sh -c "cp -rf /alfresco/* /tmp/"
cp -rf alfresco keycloak-$KEYCLOAK_VERSION/themes/
rm -rf alfresco
ls keycloak-$KEYCLOAK_VERSION/themes/alfresco

echo '# Alfresco realm import ' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf
echo 'JAVA_OPTS="$JAVA_OPTS -Dkeycloak.import=../realm/alfresco-realm.json"' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf

echo '\nrem # Alfresco realm import ' >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.bat
echo "set \"JAVA_OPTS=%JAVA_OPTS% -Dkeycloak.import=%~dp0..\\\realm\\\alfresco-realm.json\"\n:JAVA_OPTS_SET" >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.bat

echo "\n# Alfresco realm import " >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.ps1
echo "\$JAVA_OPTS += \"-Dkeycloak.import=\$pwd\\\..\\\realm\\\alfresco-realm.json\"" >> keycloak-$KEYCLOAK_VERSION/bin/standalone.conf.ps1

rm -rf alfresco-identity-$IDENTITY_VERSION
mkdir alfresco-identity-$IDENTITY_VERSION
cp -rf keycloak-$KEYCLOAK_VERSION/* alfresco-identity-$IDENTITY_VERSION/
rm -rf keycloak-$KEYCLOAK_VERSION
ls alfresco-identity-$IDENTITY_VERSION

echo packaging identity
zip -r alfresco-identity-$IDENTITY_VERSION.zip alfresco-identity-$IDENTITY_VERSION
sha1sum alfresco-identity-$IDENTITY_VERSION.zip > alfresco-identity-$IDENTITY_VERSION.zip.sha1
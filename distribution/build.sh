#!/bin/sh
set -o errexit

source $PWD/build.properties

echo "Downloading keycloak"
curl -O https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip
curl -O https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip.sha1
sha1sum -c keycloak-$KEYCLOAK_VERSION.zip.sha1

echo "unzipping keycloak"
unzip -oq keycloak-$KEYCLOAK_VERSION.zip
curl -v "http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/auth?client_id=security-admin-console&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fauth%2Fadmin%2Falfresco%2Fconsole%2F&state=cd79cde9-02d2-4b9d-8299-870e638b7b6e&response_mode=fragment&response_type=code&scope=openid&nonce=fba6bbdb-27d4-49c1-8e7f-04fb4904fa5c" | grep "Alfresco Identity Service"

echo "adding realm"
mkdir -p keycloak-$KEYCLOAK_VERSION/realm
cp ../helm/alfresco-identity-service/alfresco-realm.json keycloak-$KEYCLOAK_VERSION/realm/
sed -i'.bak' "
  s#ALFRESCO_CLIENT_REDIRECT_URIS#[\"*\"]#g;
" keycloak-$KEYCLOAK_VERSION/realm/alfresco-realm.json

echo "adding themes"
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
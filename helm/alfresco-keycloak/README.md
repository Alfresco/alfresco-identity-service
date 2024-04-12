# alfresco-keycloak

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 24.0.2](https://img.shields.io/badge/AppVersion-24.0.2-informational?style=flat-square)

This is just a sample Helm installation of raw Keycloak with the Alfresco Realm and Theme pre-installed.

**Homepage:** <https://github.com/Alfresco/alfresco-identity-service/tree/master/helm/alfresco-keycloak>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Alfresco |  |  |

## Source Code

* <https://github.com/Alfresco/alfresco-identity-service>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | common | 1.11.3 |
| https://charts.bitnami.com/bitnami | postgresql | 11.9.13 |
| https://codecentric.github.io/helm-charts | keycloakx | 2.2.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.annotations."kubernetes.io/ingress.class" | string | `"nginx"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/affinity" | string | `"cookie"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffer-size" | string | `"16k"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/session-cookie-hash" | string | `"sha1"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/session-cookie-name" | string | `"identity_affinity_route"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.path | string | `"/auth"` |  |
| ingress.pathType | string | `"Prefix"` |  |
| keycloakx.command[0] | string | `"/opt/keycloak/bin/kc.sh"` |  |
| keycloakx.command[1] | string | `"start"` |  |
| keycloakx.command[2] | string | `"--import-realm"` |  |
| keycloakx.command[3] | string | `"--http-relative-path=/auth"` |  |
| keycloakx.extraEnv | string | `"- name: KEYCLOAK_ADMIN\n  value: admin\n- name: KEYCLOAK_ADMIN_PASSWORD\n  value: admin\n- name: KEYCLOAK_IMPORT\n  value: /data/import/alfresco-realm.json\n- name: JAVA_OPTS_APPEND\n  value: >-\n    -Djgroups.dns.query={{ include \"keycloak.fullname\" . }}-headless\n"` |  |
| keycloakx.extraInitContainers | string | `"- name: theme-provider\n  image: busybox:1.36\n  imagePullPolicy: IfNotPresent\n  command:\n    - sh\n  args:\n    - -c\n    - |\n      THEME_VERSION=0.3.5\n      wget https://github.com/Alfresco/alfresco-keycloak-theme/releases/download/${THEME_VERSION}/alfresco-keycloak-theme-${THEME_VERSION}.zip -O /alfresco.zip\n      unzip alfresco.zip\n      mv alfresco/* /theme/\n  volumeMounts:\n    - name: theme\n      mountPath: /theme\n"` |  |
| keycloakx.extraVolumeMounts | string | `"- name: realm-secret\n  mountPath: \"/opt/keycloak/data/import/\"\n  readOnly: true\n- name: theme\n  mountPath: \"/opt/keycloak/themes/alfresco\"\n  readOnly: true\n"` |  |
| keycloakx.extraVolumes | string | `"- name: realm-secret\n  secret:\n    secretName: realm-secret\n- name: theme\n  emptyDir: {}\n"` |  |
| keycloakx.image.tag | string | `"24.0.2"` |  |
| keycloakx.imagePullSecrets[0].name | string | `"quay-registry-secret"` |  |
| keycloakx.rbac.create | bool | `false` |  |
| keycloakx.service.httpPort | int | `80` |  |
| keycloakx.serviceAccount.create | bool | `true` |  |
| postgresql.enabled | bool | `false` | Flag introduced for testing purposes, to actually run this with postgresql follow the approach explained [here](https://github.com/codecentric/helm-charts/blob/keycloakx-2.2.1/charts/keycloakx/examples/postgresql/readme.md). |
| realm.alfresco.adminPassword | string | `"admin"` |  |
| realm.alfresco.client.redirectUris | list | `["*"]` | For security reasons, override the default value and use URIs to be as specific as possible. [See Keycloak official documentation](https://www.keycloak.org/docs/latest/securing_apps/#redirect-uris). |
| realm.alfresco.client.webOrigins[0] | string | `"http://localhost*"` |  |
| realm.alfresco.client.webOrigins[1] | string | `"https://localhost*"` |  |
| realm.alfresco.extraGroups[0].attributes | object | `{}` |  |
| realm.alfresco.extraGroups[0].clientRoles | object | `{}` |  |
| realm.alfresco.extraGroups[0].name | string | `"testgroup"` |  |
| realm.alfresco.extraGroups[0].path | string | `"/testgroup"` |  |
| realm.alfresco.extraGroups[0].realmRoles | list | `[]` |  |
| realm.alfresco.extraGroups[0].subGroups | list | `[]` |  |
| realm.alfresco.extraRealmRoles[0].clientRole | bool | `false` |  |
| realm.alfresco.extraRealmRoles[0].composite | bool | `false` |  |
| realm.alfresco.extraRealmRoles[0].containerId | string | `"alfresco"` |  |
| realm.alfresco.extraRealmRoles[0].name | string | `"test_role"` |  |
| realm.alfresco.extraRealmRoles[0].scopeParamRequired | bool | `true` |  |
| realm.alfresco.extraUsers[0].clientRoles.account[0] | string | `"manage-account"` |  |
| realm.alfresco.extraUsers[0].clientRoles.account[1] | string | `"view-profile"` |  |
| realm.alfresco.extraUsers[0].credentials[0].type | string | `"password"` |  |
| realm.alfresco.extraUsers[0].credentials[0].value | string | `"password"` |  |
| realm.alfresco.extraUsers[0].disableableCredentialTypes[0] | string | `"password"` |  |
| realm.alfresco.extraUsers[0].email | string | `"test@test.com"` |  |
| realm.alfresco.extraUsers[0].emailVerified | bool | `false` |  |
| realm.alfresco.extraUsers[0].enabled | bool | `true` |  |
| realm.alfresco.extraUsers[0].firstName | string | `"test"` |  |
| realm.alfresco.extraUsers[0].groups[0] | string | `"/admin"` |  |
| realm.alfresco.extraUsers[0].groups[1] | string | `"/testgroup"` |  |
| realm.alfresco.extraUsers[0].lastName | string | `"test"` |  |
| realm.alfresco.extraUsers[0].realmRoles[0] | string | `"uma_authorization"` |  |
| realm.alfresco.extraUsers[0].realmRoles[1] | string | `"user"` |  |
| realm.alfresco.extraUsers[0].realmRoles[2] | string | `"offline_access"` |  |
| realm.alfresco.extraUsers[0].realmRoles[3] | string | `"test_role"` |  |
| realm.alfresco.extraUsers[0].totp | bool | `false` |  |
| realm.alfresco.extraUsers[0].username | string | `"testuser"` |  |

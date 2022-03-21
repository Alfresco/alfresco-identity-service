# alfresco-identity-service

![Version: 6.0.0](https://img.shields.io/badge/Version-6.0.0-informational?style=flat-square) ![AppVersion: 1.7.0](https://img.shields.io/badge/AppVersion-1.7.0-informational?style=flat-square)

The Alfresco Identity Service will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication.

**Homepage:** <https://github.com/Alfresco/alfresco-identity-service/tree/master/helm/alfresco-identity-service>

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
| https://codecentric.github.io/helm-charts | keycloak | 16.1.0 |

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
| keycloak.extraEnv | string | `"- name: KEYCLOAK_USER\n  value: admin\n- name: KEYCLOAK_PASSWORD\n  value: admin\n- name: KEYCLOAK_IMPORT\n  value: /realm/alfresco-realm.json\n"` |  |
| keycloak.extraVolumeMounts | string | `"- name: realm-secret\n  mountPath: \"/realm/\"\n  readOnly: true\n"` |  |
| keycloak.extraVolumes | string | `"- name: realm-secret\n  secret:\n    secretName: realm-secret\n"` |  |
| keycloak.image.pullPolicy | string | `"Always"` |  |
| keycloak.image.repository | string | `"quay.io/alfresco/alfresco-identity-service"` |  |
| keycloak.image.tag | string | `"1.7.0"` |  |
| keycloak.imagePullSecrets[0].name | string | `"quay-registry-secret"` |  |
| keycloak.postgresql.enabled | bool | `true` |  |
| keycloak.postgresql.nameOverride | string | `"postgresql-id"` |  |
| keycloak.postgresql.persistence.enabled | bool | `true` |  |
| keycloak.postgresql.persistence.existingClaim | string | `""` |  |
| keycloak.postgresql.persistence.subPath | string | `"alfresco-identity-service/database-data"` |  |
| keycloak.postgresql.postgresqlPassword | string | `"keycloak"` |  |
| keycloak.postgresql.resources.limits.memory | string | `"500Mi"` |  |
| keycloak.postgresql.resources.requests.memory | string | `"250Mi"` |  |
| keycloak.rbac.create | bool | `false` |  |
| keycloak.service.httpPort | int | `80` |  |
| keycloak.serviceAccount.create | bool | `true` |  |
| realm.alfresco.adminPassword | string | `"admin"` |  |
| realm.alfresco.client.redirectUris[0] | string | `"*"` |  |
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

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.7.0](https://github.com/norwoodj/helm-docs/releases/v1.7.0)

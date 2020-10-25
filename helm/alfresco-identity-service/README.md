# alfresco-identity-service

![Version: 2.1.1-SNAPSHOT](https://img.shields.io/badge/Version-2.1.1--SNAPSHOT-informational?style=flat-square) ![AppVersion: 1.4.0-SNAPSHOT](https://img.shields.io/badge/AppVersion-1.4.0--SNAPSHOT-informational?style=flat-square)

The Alfresco Identity Service will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication.

**Homepage:** <https://github.com/Alfresco/alfresco-identity-service/helm>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Alfresco |  |  |

## Source Code

* <https://github.com/Alfresco/alfresco-identity-service/helm>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://codecentric.github.io/helm-charts | keycloak | 8.2.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hyperkube.image.pullPolicy | string | `"IfNotPresent"` |  |
| hyperkube.image.repository | string | `"quay.io/coreos/hyperkube"` |  |
| hyperkube.image.tag | string | `"v1.9.6_coreos.2"` |  |
| ingress.annotations."kubernetes.io/ingress.class" | string | `"nginx"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/affinity" | string | `"cookie"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffer-size" | string | `"16k"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/session-cookie-hash" | string | `"sha1"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/session-cookie-name" | string | `"identity_affinity_route"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.path | string | `"/auth"` |  |
| keycloak.keycloak.extraArgs | string | `"-Dkeycloak.import=/realm/alfresco-realm.json"` |  |
| keycloak.keycloak.extraVolumeMounts | string | `"- name: realm-secret\n  mountPath: \"/realm/\"\n  readOnly: true\n"` |  |
| keycloak.keycloak.extraVolumes | string | `"- name: realm-secret\n  secret:\n    secretName: realm-secret\n"` |  |
| keycloak.keycloak.image.pullPolicy | string | `"Always"` |  |
| keycloak.keycloak.image.pullSecrets[0] | string | `"quay-registry-secret"` |  |
| keycloak.keycloak.image.repository | string | `"quay.io/alfresco/alfresco-identity-service"` |  |
| keycloak.keycloak.image.tag | string | `"1.4.0-SNAPSHOT"` |  |
| keycloak.keycloak.password | string | `"admin"` |  |
| keycloak.keycloak.persistence.dbPassword | string | `"keycloak"` |  |
| keycloak.keycloak.persistence.dbVendor | string | `"postgres"` |  |
| keycloak.keycloak.persistence.deployPostgres | bool | `true` |  |
| keycloak.keycloak.service.port | int | `80` |  |
| keycloak.keycloak.serviceAccount.create | bool | `true` |  |
| keycloak.keycloak.username | string | `"admin"` |  |
| keycloak.persistence.deployPostgres | bool | `true` |  |
| keycloak.postgresql.backup.image | string | `"postgres:11.1"` |  |
| keycloak.postgresql.backup.password_key | string | `"postgresql-password"` |  |
| keycloak.postgresql.nameOverride | string | `"postgresql-id"` |  |
| keycloak.postgresql.persistence.enabled | bool | `true` |  |
| keycloak.postgresql.persistence.existingClaim | string | `"alfresco-volume-claim"` |  |
| keycloak.postgresql.persistence.subPath | string | `"alfresco-identity-service/database-data"` |  |
| keycloak.postgresql.postgresqlPassword | string | `"keycloak"` |  |
| keycloak.postgresql.resources.limits.memory | string | `"500Mi"` |  |
| keycloak.postgresql.resources.requests.memory | string | `"250Mi"` |  |
| keycloak.postgresql.restore.image | string | `"postgres:11.1"` |  |
| keycloak.postgresql.restore.password_key | string | `"postgresql-password"` |  |
| keycloak.rbac.create | bool | `false` |  |
| realm.alfresco.client.redirectUris[0] | string | `"http://localhost*"` |  |
| realm.alfresco.client.redirectUris[1] | string | `"https://localhost*"` |  |
| realm.alfresco.client.webOrigins[0] | string | `"http://localhost*"` |  |
| realm.alfresco.client.webOrigins[1] | string | `"https://localhost*"` |  |
| realm.alfresco.extraGroups[0].name | string | `"testgroup"` |  |
| realm.alfresco.extraGroups[0].path | string | `"/testgroup"` |  |
| realm.alfresco.extraRealmRoles[0].clientRole | bool | `false` |  |
| realm.alfresco.extraRealmRoles[0].composite | bool | `false` |  |
| realm.alfresco.extraRealmRoles[0].containerId | string | `"alfresco"` |  |
| realm.alfresco.extraRealmRoles[0].name | string | `"test_role"` |  |
| realm.alfresco.extraRealmRoles[0].scopeParamRequired | bool | `true` |  |
| realm.alfresco.extraUsers[0].clientRoles.account[0] | string | `"manage-account"` |  |
| realm.alfresco.extraUsers[0].clientRoles.account[1] | string | `"view-profile"` |  |
| realm.alfresco.extraUsers[0].credentials[0].algorithm | string | `"pbkdf2"` |  |
| realm.alfresco.extraUsers[0].credentials[0].counter | int | `0` |  |
| realm.alfresco.extraUsers[0].credentials[0].digits | int | `0` |  |
| realm.alfresco.extraUsers[0].credentials[0].hashIterations | int | `20000` |  |
| realm.alfresco.extraUsers[0].credentials[0].hashedSaltedValue | string | `"+A2UrlK6T33IHVutjQj9k8S8kMco1IMnmCTngEg+PE+2vO4jJScux6wcltsRIYILv5ggcS3PI7tbsynq5u39sQ=="` |  |
| realm.alfresco.extraUsers[0].credentials[0].period | int | `0` |  |
| realm.alfresco.extraUsers[0].credentials[0].salt | string | `"IyVlItIo27bmACSLi4yQkA=="` |  |
| realm.alfresco.extraUsers[0].credentials[0].type | string | `"password"` |  |
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
Autogenerated from chart metadata using [helm-docs v1.3.0](https://github.com/norwoodj/helm-docs/releases/v1.3.0)

## Keycloak Sample Distribution

![Completeness Badge](https://img.shields.io/badge/Document_Level-In_Progress-yellow.svg?style=flat-square)

![Version Badge](https://img.shields.io/badge/Version-1.0-ff69b4.svg?style=flat-square)

### Purpose
Keycloak was initially introduced to the architecture as a means for Client Applications to implement single sign-on
across components of the Digital Business Platform (via [OpenID Connect](https://openid.net/connect/)) while providing the option to 
delegate authentication of the user to an external Identity Provider over protocols like SAML, OpenID Connect, and LDAP.

*** 


### Overview
More information can be found over at [Keycloak](https://www.keycloak.org/).  An example
realm file containing a pre-defined 'alfresco' client and login theme are imported on bootstrap.

Client Applications can obtain a JSON Web Token (JWT) via OpenID Connect which can then be presented in a Bearer Authorization header
in an HTTP request against REST APIs of Alfresco components such as Process Services and Content Services.

The primary deployment mechanism is via a Kubernetes Helm chart.

*** 

### Artifacts and Guidance

* Source Code
  * https://github.com/Alfresco/alfresco-identity-service
  * https://github.com/Alfresco/alfresco-keycloak-theme
* License: Apache 2
* Issue Tracker: https://issues.alfresco.com/jira/projects/AUTH
* Documentation: TODO
* Contributions: https://github.com/Alfresco/alfresco-identity-service/blob/master/CONTRIBUTING.md

*** 

### Prerequisite Knowledge
A basic understanding of the following would be helpful in understanding Keycloak:
* OAuth 2
* OpenID Connect
* SAML
* LDAP
* Kubernetes
* Helm

*** 

### Design

#### Component Model

The components typically involved in a Client Application's single-sign on against DBP REST APIs is perhaps best viewed in the
context of the Kubernetes deployment:

![Keycloak Sample Components](resource/component/keycloak-sample-components.png "Keycloak Sample Components")

#### Data Model

See the [ADR on JWT details](adrs/0001-Internal-JWT-Token-Details.md).

#### Flows

The details of various auth protocols like SAML and OpenID Connect are readily available on the web so we won't repeat them here,
but below are high-level overviews of a few common scenarios:

##### Auth Against LDAP

![Alfresco JWT (Implicit) Authentication Against Keycloak Configured for LDAP](resource/sequence/high-level-ldap-auth-sequence.png "Alfresco JWT (Implicit) Authentication Against Keycloak Configured for LDAP")

##### Auth Against SAML

![Alfresco JWT (Implicit) Authentication Against Keycloak Configured for SAML](resource/sequence/high-level-saml-auth-sequence.png "Alfresco JWT (Implicit) Authentication Against Keycloak Configured for SAML")

### APIs and Interfaces

In its initial introduction, only the endpoints necessary for SAML and Open ID Connect protocols are supported for Keycloak.

From a UI perspective, an Alfresco login theme is provided, but the admin console is Keycloak's default.

*** 

### Configuration

See the [config directory](config) for details on common configurations.

*** 

### Performance Considerations

The Keycloak chart supports specifying [multiple replicas](https://github.com/codecentric/helm-charts/blob/master/charts/keycloak#high-availability-and-clustering).

See Keycloak's documentation on configuring [high availability and clustering](https://www.keycloak.org/docs/latest/server_installation/index.html#_clustering).

Also see the Identity Service [README](https://github.com/Alfresco/alfresco-identity-service#multiple-replicas-high-availability-and-clustering).

*** 

### Security Considerations

See Keycloak's [Server Admin documentation](https://www.keycloak.org/docs/latest/server_admin/index.html).

*** 

### Cloud Considerations

As a standard Kubernetes deployment Keycloak can easily be deployed to Cloud environments including managed clusters like AWS
EKS.

See the documentation for specifics on ingress considerations or leveraging native database services rather than deploying Postgresql.

***

### Design Decisions

See the [adrs directory](adrs). 

# Alfresco Identity Service

The Alfresco Identity Service provides a Single Sign On experience for the Alfresco Digital Business Platform (DBP).

The Identity Service is based on [Keycloak](http://www.keycloak.org) and provides a [sample realm](./alfresco-realm.json) file for use with the DBP.

## Setup Keycloak

There are several ways to install Keycloak, via [distribution files](http://www.keycloak.org/docs/3.4/server_installation/index.html#installation), an official [Docker image](https://hub.docker.com/r/jboss/keycloak/) or a [Helm chart](https://github.com/kubernetes/charts/tree/master/incubator/keycloak).

When installing use the appropriate configuration option to create an "admin" user, this will be used as the administrator login for Alfresco Content Services (ACS) and Alfresco Process Services (APS).

## Configure Alfresco Realm

Once Keycloak is up and running login to the [Management Console](http://www.keycloak.org/docs/3.4/server_admin/index.html#admin-console) to configure the required realm, you can either do this manually or using the sample realm file.

### Manually

1. [Add a realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.4/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.4/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

### Sample Realm

Go to the [Add Realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

Choose the [alfresco-realm.json](./alfresco-realm.json) file and click the "Create" button.
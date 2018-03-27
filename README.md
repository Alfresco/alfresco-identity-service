# Alfresco Identity Service

The Alfresco Identity Service provides a Single Sign On experience for the Alfresco Digital Business Platform (DBP).

The Identity Service is based on [Keycloak](http://www.keycloak.org) and provides a [sample realm](./alfresco-realm.json) file for use with the DBP.

# Setup Keycloak

There are several ways to install Keycloak, via [distribution files](http://www.keycloak.org/docs/3.3/server_installation/topics/installation.html), an official [Docker image](https://hub.docker.com/r/jboss/keycloak/) or a [Helm chart](https://github.com/kubernetes/charts/tree/master/incubator/keycloak).

When installing use the appropriate configuration option to create an "admin" user, this will be used as the administrator login for Alfresco Content Services (ACS) and Alfresco Process Services (APS).

# Configure Alfresco Realm

Once Keycloak is up and running login to the [Management Console](http://www.keycloak.org/docs/3.3/server_admin/topics/admin-console.html) to configure the required realm, you can either do this manually or using the sample realm file.

## Manually

1. [Add a realm](http://www.keycloak.org/docs/3.3/server_admin/topics/realms/create.html) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.3/server_admin/topics/clients/client-oidc.html) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.3/server_admin/topics/groups.html) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.3/server_admin/topics/users/create-user.html) with a username of "testuser", email of "test@test.com" and first and last name of "test"

5. [Assign](http://www.keycloak.org/docs/3.3/server_admin/topics/groups.html) the newly created testuser to the "admin" group.

## Sample Realm

Go to the [Add Realm](http://www.keycloak.org/docs/3.3/getting_started/topics/first-realm/realm.html) page and click the "Select File" button next to the **Import** label. 

Choose the [alfresco-realm.json](./alfresco-realm.json) file and click the "Create" button.
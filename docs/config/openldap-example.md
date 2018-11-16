# Configuring an OpenLDAP instance with the Alfresco Identity Service

The Identity Service can be configured to use an OpenLDAP instance for user federation. The following steps detail this configuration.

## Prerequisites

Ensure you have installed the Identity Service before starting. You will also need to have access to, or the details of, your OpenLDAP instance.

## Configuration

1. Sign in to the administrator panel of the Identity Service using the following URL: `https://$ELBADDRESS/auth/admin`
 
   **Note:** The `$ELBADDRESS` will be the one used [during deployment](../../README.md).

2. Select the correct realm to configure OpenLDAP against.

   **Note:** If using the default deployment options, the realm will be called `Alfresco`.

3. Select **User Federation** from the navigation menu and choose *ldap* in the **Add Provider** dropdown.

4. Once you choose *Other* from the **Vendor** dropdown, the LDAP attribute fields will populate.

 
5. Verify that these auto-populated fields are correct for your LDAP configuration.

    * For **Connection URL** the format is as follows:
        
        ```ldap//<LDAP Hostname>:<LDAP Port>``` or
         
        ```ldaps://<LDAP Hostname>:<LDAP Port>``` for SSL-enabled LDAP installations
        
        **Note:** If your [OpenLDAP Helm Chart](https://github.com/helm/charts/tree/master/stable/openldap) is installed in the same namespace as the Identity Service, then you can use your OpenLDAPS's Helm release name for `<LDAP Hostname>`.

6. Verify your configuration settings are correct by using the **Test connection** and **Test authentication** buttons.

    **Note:** The **Test authentication** option requires data in your OpenLDAP instance to run successfully.

7. **Save** your configuration.
   
[Detailed descriptions of the configuration options](https://www.keycloak.org/docs/4.2/server_admin/index.html#_ldap) are available as part of the Keycloak documentation if required.
   
## Post-configuration user synchronization
Users from your OpenLDAP instance can either be periodically synchronized using a background job or you can choose to have users imported into the Identity Service database the first time they authenticate against the Identity Service.

The [advantages to each approach](https://www.keycloak.org/docs/4.2/server_admin/index.html#storage-mode) are detailed as part of the Keycloak documentation.
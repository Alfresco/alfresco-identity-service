## Configuring OpenLDAP as an LDAP Identity Provider

Alfresco Identity Service can be configured to use OpenLdap as an LDAP identity provider
by following these steps:

### Configure KeyCloak
1. Login to Alfresco Identity Service: `https://$ELBADDRESS/auth/admin`  
   (please refer to the main [README](../../README.md) document for details about the `$ELBADDRESS` parameter)
2. Ensure the realm for which the LDAP user federation provider needs to be configured is selected. For out of the box
   Alfresco Identity Service installations this realm will be called `Alfresco` and will be open upon logging on
   to your Alfresco Identity Service instance.
3. Click "User Federation".
4. In "Add Provider" dropdown menu select "ldap".
5. In "Vendor" dropdown menu select "Other".
6. LDAP attribute fields will auto-populate. Verify that they are valid for your LDAP configuration.
7. In "Connection URL" field enter `ldap://<LDAP hostname>:<LDAP port>` or, if you use SSL-enabled
   LDAP server, `ldaps://<LDAP hostname>:<LDAPS port>`.
   
   If your [OpenLDAP helm chart](https://github.com/helm/charts/tree/master/stable/openldap) is installed in the same 
   namespace as that of the Alfresco Identity Server, for `LDAP hostname` you can simply use the OpenLDAP instance's 
   helm release name. 
   
   If you need any help with configuration options, they are documented in the [Keycloak Server Administration Guide](https://www.keycloak.org/docs/3.4/server_admin/index.html#_ldap). 
   
   When complete, your LDAP configuration will look similar to that used in 
   [Identity Service Tests With LDAP provider](../../test/postman/README.ldap-user-provider-tests.md).
8. Click "Test connection". Provided your LDAP connection was configured correctly, you should
   get the message "Success! LDAP connection successful".
9. Click "Test authentication". Provided your test data was imported
   correctly in step 3, you should get the message "Success! LDAP authentication 
   successful".
10. Click "Save".

You will now be able to synchronize changed users, synchronise all users etc. You can opt to do this or, 
alternatively, let LDAP-federated users be automatically imported to the KeyCloak user
database first time they authenticate against your Alfresco Identity Service instance.
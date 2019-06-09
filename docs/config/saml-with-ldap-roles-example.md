# Configuring the Alfresco Identity Service with SAML for Authn and LDAP for Roles

In some cases there may be a need for the Identity Service to delegate authentication to a SAML IdP which does not have the ability to return role information in the SAML assertion, and can instead retrieve that role information from an LDAP provider.

The following can serve as a high-level guide which can be combined with sections from the more specific OpenLDAP and PingFederate examples or adapted to other environments.

The example assumes a trusted environment between the Identity Service, SAML IdP, and LDAP provider such that users will not be prompted to confirm account details or linking at the Identity Service.

The example also assumes the additional user information should be obtained from LDAP in a just-in-time manner during user provisioning after successful validation of a SAML assertion.

## Prerequisites

Ensure you have installed the Identity Service before starting. You will also need to have access to, or the details of, your LDAP and SAML IdP environments.

## Configuration

1. Sign in to the administrator panel of the Identity Service using the following URL: `https://$ELBADDRESS/auth/admin`

   **Note:** The `$ELBADDRESS` will be the one used [during deployment](../../README.md).

2. Select the correct realm to configure.

   **Note:** If using the default deployment options, the realm will be called `Alfresco`.

3. Select **Authentication** from the navigation menu and click the *New* button, give it an alias such as "auto link broker" and click the *Save* button.

4. Click the *Add execution* button and select *Create User If Unique* and click the *Save* button.

5. Click the *Add execution* button and select *Automatically Link Brokered Account* and click the *Save* button.

6. Set both execution requirements to *Alternative*.

7. Create a SAML **Identity Provider** at the Identity Service and a service provider at your IdP as described in the the [PingFederate example](../ping-federate-example.md) or the Keycloak documentation.

8. Change the *First Login Flow* to the Authentication Flow you created in step 3.

9. Create an LDAP **User Federation** provider as described in the [OpenLDAP example](../openldap-example.md) or the Keycloak documentation.

10. Set *Edit Mode* to `READ_ONLY` and click *Save*.

11. Navigate to the **Mappers** tab and select **Create**.

12. Give the mapper a name such as `roles`.

13. Select a *Mapper Type* of `role-ldap-mapper`, fill in the details for your environment's LDAP roles and click *Save*.

## Post-configuration confirmation

Once the above steps are complete you should be able to do the following to quickly confirm that LDAP roles are being passed to the JWT presented to Alfresco components for authentication:

1. Navigate to a URL to request a token such as:
```
https://$ELBADDRESS/auth/realms/alfresco/protocol/openid-connect/auth?response_type=id_token%20token&client_id=alfresco&redirect_uri=http%3A%2F%2Flocalhost%2Fdummy_redirect&scope=openid%20profile%20email&nonce=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs
```
2. Depending on your Identity Service configuration you may be presented with a login screen from the Identity Service where you'll need to click the button to login via the SAML IdP (or you may be automatically redirected there).

3. Enter user credentials at the SAML IdP.

4. You should then be authenticated at both the SAML IdP then the Identity Service, then redirected to a 'broken' `http://localhost/dummy_redirect` URL containing additional URL parameters. Copy the value of the `access_token` parameter.

5. Navigate to [jwt.io](https://jwt.io) and paste the token into the *Encoded* box then inspect the *Payload* in the *Decoded* panel and confirm the user's LDAP roles are contained in the `realm_access.roles` JSON array.

## Configuring PingFederate as SAML2 IDP

Alfresco Identity Service can be configured to use PingFederate as a SAML 2.0 identity provider
by following these steps:

### Obtaining PingFederate Parameters
1. Log in to your PingFederate instance as a user with administrative privileges
2. Under "System Settings" heading click "Server Settings"
3. Under "Federation Info" heading note the value of "My Base URL"
4. Click "Main"
5. Under "Federation Settings" heading click "Protocol Endpoints"
6. In "SAML v2.0 Endpoints" section, take note of POST endpoints for 
   "Single Logout (SLO) Service" and "Single Sign-on (SSO) Service" respectively

The corresponding service URLs are constructed by appending endpoint values from step 6
to base URL (step 5). You will need these values to configure your KeyCloak instance.

Example:
> If Base Url value is "https://pingfederate.test.com:9031" and POST
  SLO endpoint "/idp/SLO.saml2", the POST SLO service URL is 
  "https://pingfederate.test.com:9031/idp/SLO.saml2"

### Configuring KeyCloak Identity Provider
1. Login to Alfresco Identity Service: https://$ELBADDRESS/auth/admin  
   (please refer to the main [README](./README.md) document for details about the `$ELBADDRESS` parameter)
2. Click "Identity Providers"
3. In "Add provider..." menu select "SAML v2.0"
4. In "Single Sign-On Service URL" and "Single Logout Service URL" enter 
   previously noted values
5. In "NameID Policy Format" dropdown select "Unspecified"
6. Enable "HTTP-POST Binding Response"
7. Enable "HTTP-POST Binding for AuthnRequest"
8. Enable "HTTP-POST Binding Logout"
9. Enable "Want AuthnRequests Signed"
10. In "Signature Algorithm" chose signature algorithm appropriate for
   for your setup (e.g. "RSA_SHA_256")
11. In "SAML Signature Key Name" dropdown menu select "NONE"
12. Click "Save"
13. Click "Mappers" tab
14. Click "Create"
15. In "Mapper Type" dropdown select "Attribute Importer"
16. In "Name" textbox type "email"
17. In "Attribute Name" textbox type "EMAIL"
18. In "Friendly Name" textbox type "email"
19. In "User Attribute Name" textbox type "email"
20. Click "Save"
21. Click "Export" tab
22. Click "Download" button and take note of the downloaded file 
    name and location
23. Create a file with extension ".cert" (pick an arbitrary name) with the following content:
    ```
    -----BEGIN CERTIFICATE-----
    -----END CERTIFICATE-----
    ```
24. Open the file created in step 22 using a text editor
25. Find a line beginning with `<dsig:X509Certificate>` and ending with `</dsig:X509Certificate>` XML tag
26. Copy the string in between `<dsig:X509Certificate>` and `</dsig:X509Certificate>` and paste
    it into the file created in step 23 in-between `-----BEGIN CERTIFICATE-----` and
    `-----END CERTIFICATE-----`.
    
    When completed, your `.cert` file should look similar to:
    ```
    -----BEGIN CERTIFICATE-----
    MIICnzCCAYcCBgFkqEAQCDANBgkqhkiG9w0BAQsFADATMREwDwYDVQQDDAhhbGZyZXNjbzA
    -----END CERTIFICATE-----
    ```

TODO: "Valid Redirect URIs" in clients!

### Configuring PingFederate Connection
1. Log in to your PingFederate Instance
2. Under "SP Connections" heading click "Create New"
3. Verify the "Browser SSO Profiles" connection template with value 
   "Protocol SAML 2.0" is selected. Click "Next"
4. Under "Connection Options" heading make sure only "Browser SSO" 
   is selected. Click "Next"
5. Under "Import Metadata" heading click "Choose file" and select 
   the file downloaded in the previous section. Click "Next".
6. Under "Metadata Summary" heading click "Next"
7. Under "General Info" heading verify the imported values correspond
   that of your KeyCloak setup. Click "Next".
8. Under "Browser SSO" heading click "Configure Browser SSO" button.
9. Tick all 4 checkboxes (IdP and SP Initiated SSo + IdP and SP Initiated SLO). 
   Click "Next".
10. Under "Assertion Lifetime" heading click "Next"
11. Under "Assertion Creation" heading click "Configure Assertion Creation" button.
12. Under "Identity Mapping" heading click "Next"
13. Under "Attribute Contract" heading in "Extend the contract" textbox type "Email".
14. In "Attribute name format" dropdown menu ensure the value "urn:oasis:names:tc:SAML:2.0:attrname-format:basic" is 
    selected. Click "Add". Click "Next".
15. Under "Authentication Source Mapping" heading click "Map New Adapter Instance..." button.
16. In "Adapter Instance" dropdown menu select "IdP Adapter". Click "Next".
17. Under "Assertion Mapping" heading click "Next"
18. Under "Attribute Contract Fulfillment" heading:
    - In "Email" row: 
        - In "Source" dropdown menu select "Adapter"
        - In "Value" dropdown menu select "email"    
    - In "SAML_SUBJECT" row:
        - In "Source" dropdown menu select "Adapter"
        - In "Value" dropdown menu select "subject"
    
    Click "Next".
19. Under "Issuance Criteria" heading click "Next"
20. Under "Summary" heading click "Done"
21. Under "Authentication Source Mapping" heading click "Next"
22. Under "Summary" heading click "Done"
23. Under "Assertion Creation" heading click "Next"
24. Under "Protocol Settings" heading click "Configure Protocol Settings"
25. In "default" row verify binding "POST" points to your Keycloak endpoint.
    Click "Next".
26. Under "SLO Service URLs" heading verify binding "POST" points to your Keycloak endpoint.
    Click "Next".
27. Under "Allowable SAML Bindings" heading untick all checkboxes except for "POST".
    Click "Next".
28. Under "Signature Policy" heading untick "Require AuthN requests to be signed when received via the POST or Redirect 
    bindings" checkbox. Click "Next".
29. Under "Encryption Policy" heading ensure "None" checkbox is ticked.
    Click "Next".
30. Click "Done".
31. Under "Protocol Settings" heading click "Next"
32. Under "Summary" heading click "Done"
33. Under "Browser SSO" heading click "Next"
34. Under "Credentials" heading click "Configure Credentials" button.
35. In "Signing Certificate" dropdown menu select your organization's certificate. 
    Click "Next".
36. Under "Signature Verification Settings" heading click "Manage Signature Verification Settings" button.
37. Under "Trust Model" heading click "Unanchored". Click "Next".
38. Under "Signature Verification Certificate" click "Manage Certificate" button.
39. Click "Import"
40. In "Filename" row Click "Browse" button and selected the exported Keycloak certificate. Click "Next".
41. Take note of the imported certificate's Serial Number. Click "Done".
42. Under "Signature Verification Certificate" heading in "Primary" dropdown
    menu select the certificate with ID from previous step. Click "Next".
43. Click "Done"
44. Under "Signature Verification Settings" heading click "Next"
45. Under "Summary" heading click "Done"
46. Under "Credentials" heading click "Next"
47. Under "Activation & Summary" heading in "Connection Status" row tick checkbox "Active". Click "Save".

Your new connection should now appear in "SP Connections" list.
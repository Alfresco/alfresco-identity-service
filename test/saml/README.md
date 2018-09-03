# Alfresco Identity Service Token Test
Test that a valid JWT Token can be generated when authenticating with SAML.

### _Assumptions_
- Uses PingFederate as SAML IDP
- Uses Alfresco Identity Service
- That a user exists in the Keycloak realm that matches the SAML user

The test is implemented using Junit 5 and Selenium Server.

The test can be run using `mvn clean test`.

The following properties can be set

| Propety | Description | Environment Variable |  Default |
|---|---|---|---|
| keycloak.hostname | The hostname of the keycloak server used by the Identity Service | KEYCLOAK_HOSTNAME  | localhost |
| keycloak.issuer | The issuer of the JWT | KEYCLOAK_ISSUER  | https://localhost/auth/realms/alfresco |
| keycloak.realm | The realm that the keycloak client is configured to use | KEYCLOAK_REALM | alfresco |
| saml.username | The SAML Username | SAML_USERNAME | userA |
| saml.password | The SAML User's Password  | SAML_PASSWORD | password |
| enable.browser | Run Headless or in Browser  |  | false |

### Using a browser
By default, the test is run in a headless browser.  There are times that you may want to see the test run in a browser.  You can accomplish this by setting `enable.browser` to true in `application.properties`.  Change the property to true makes a couple of assumptions
1. You have the Chrome Browser installed.
2. You have the selenium chromedriver installed. You can find instructions on how to install the chromedriver [here](https://github.com/SeleniumHQ/selenium/wiki/ChromeDriver).

If you would like to use another browser you will need to modify `TokenTest.java`

package org.alfresco.identity.service.saml.test;

import org.openqa.selenium.By;

/**
 * @author Jared Ottley
 */

public final class TokenTestConstants
{
    //Property File Keys
    public final static String PROP_SAML_USERNAME = "saml.username";
    public final static String PROP_SAML_PASSWORD = "saml.password";
    public final static String PROP_KEYCLOAK_HOSTNAME = "keycloak.hostname";
    public final static String PROP_KEYCLOAK_ISSUER = "keycloak.issuer";
    public final static String PROP_KEYCLOAK_REALM = "keycloak.realm";
    public final static String PROP_KEYCLOAK_THEME = "keycloak.theme";
    public final static String PROP_ENABLE_BROWSER = "enable.browser";

    //Page Elements
    // SAML button selector varies depending on applied theme
    public final static By ELEMENT_SAML_KEYCLOAK = By.linkText("saml");
    public final static By ELEMENT_SAML_ALFRESCO = By.cssSelector("input[value=saml]");

    public final static String ELEMENT_USERID = "username";
    public final static String ELEMENT_PASWORD = "password";

    //Header Parameters
    public final static String HEADER_ACCESS_TOKEN = "access_token";

    //Key Factory Algorithims
    public final static String ALGORITHIM_RSA = "RSA";

    //JSON Keys
    public final static String KEY_PUBLIC_KEY = "public_key";

    // Themes
    public final static String ALFRESCO_THEME_NAME = "alfresco";
}
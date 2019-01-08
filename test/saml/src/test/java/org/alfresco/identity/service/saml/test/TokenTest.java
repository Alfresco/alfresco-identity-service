package org.alfresco.identity.service.saml.test;

import static org.alfresco.identity.service.saml.test.TokenTestConstants.*;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.net.MalformedURLException;
import java.security.KeyFactory;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.net.ssl.SSLContext;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import org.openqa.selenium.By.ByLinkText;
import org.openqa.selenium.By.ByName;
import org.openqa.selenium.chrome.ChromeDriverService;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.conn.ssl.NoopHostnameVerifier;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.ssl.SSLContextBuilder;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.htmlunit.HtmlUnitDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.support.ui.Select;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * @author Jared Ottley
 */
@TestInstance(Lifecycle.PER_CLASS)
 public class TokenTest
{  
    private Logger logger = LoggerFactory.getLogger(TokenTest.class);
    private Properties appProps = null;
    private ChromeDriverService service = null;

    @BeforeAll
    void setup()
    {
        try
        {
        String rootPath = Thread.currentThread().getContextClassLoader().getResource("").getPath();
        String appConfigPath = rootPath + "application.properties";
 
        appProps = new Properties();
        appProps.load(new FileInputStream(appConfigPath));
        }
        catch (IOException exception)
        {
            logger.info("Unable to read properties file");
        }
    }

    @AfterAll
    void cleanup()
    {
        //Clean up remote chromedriver service
        if (service != null)
        {
            service.stop();
        }
    }

    @Test
    void getTokenFromSAMLLogin() 
    throws MalformedURLException, 
           IOException, 
           NoSuchAlgorithmException, 
           InvalidKeySpecException, 
           Exception
    {   
        //Create HTMLUnit WebDriver
        WebDriver driver;

        if(!isBrowserEnable())
        {
            driver = new HtmlUnitDriver(true);
        }
        else
        {
            ChromeDriverService service = new ChromeDriverService.Builder().usingAnyFreePort().build();
            service.start();
            driver = new RemoteWebDriver(service.getUrl(), DesiredCapabilities.chrome());
        }
        
        //Initiate page
        driver.get("https://" + getHostname() + "/auth/realms/" + getRealm() +"/protocol/openid-connect/auth?response_type=id_token%20token&client_id=alfresco&state=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs&redirect_uri=http%3A%2F%2F" + getHostname() + "%2Fdummy_redirect&scope=openid%20profile%20email&nonce=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs");
        logger.info("Login page URL: " + driver.getCurrentUrl());

        //Click on SAML link on login page, the link is theme-dependent
        String themeName = getTheme();
        WebElement element = driver.findElement(
            themeName.compareTo(ALFRESCO_THEME_NAME) == 0 ? ELEMENT_SAML_ALFRESCO : ELEMENT_SAML_KEYCLOAK);
        element.click();

        //Select User, Enter password, and submit form on SAML page
        Select select = new Select(driver.findElement(ByName.name(TokenTestConstants.ELEMENT_USERID)));
        select.selectByVisibleText(getUser());
        WebElement passwordField = driver.findElement(ByName.name(TokenTestConstants.ELEMENT_PASWORD));
        passwordField.sendKeys(getPassword());

        passwordField.submit();
        
        //Get the redirect URL for validation -- If you check the status of the
        //redirct URL call it will be 404.  The page does not exist. All we are
        //intersted in is the token parameter in the URL
        logger.info("Redirect URL: " + driver.getCurrentUrl());

        //Get token param
        Map<String, String> params = getQueryStringMap(driver.getCurrentUrl());
        String token = params.get(TokenTestConstants.HEADER_ACCESS_TOKEN);
        logger.info("access_token parameter: " + token);
        

        //Decode token and verify token
        DecodedJWT jwt = null;
        try
        {
            //Get public key
            String public_key = getPublicKey();
            logger.info("public_key: " + public_key);

            //Get RSA Key Factory
            KeyFactory kf = KeyFactory.getInstance(TokenTestConstants.ALGORITHIM_RSA);

            X509EncodedKeySpec keySpecX509 = new X509EncodedKeySpec(Base64.decodeBase64(public_key));
            RSAPublicKey pubKey = (RSAPublicKey) kf.generatePublic(keySpecX509);
            Algorithm algorithm = Algorithm.RSA256(pubKey, null);
            logger.info("issuer: " + getIssuer());
            JWTVerifier verifier = JWT.require(algorithm)
                .withIssuer(getIssuer())
                .build(); //Reusable verifier instance
            jwt = verifier.verify(token);
            logger.info("Payload Decoded: " + new String(Base64.decodeBase64(jwt.getPayload().getBytes())));
        }
        catch (JWTVerificationException exception)
        {
            logger.info("Verfication failed");
        }

        assertNotNull(jwt);  
        
        //Quit Driver session
        driver.quit();

    }

    //Utility Methods
    private Map<String, String> getQueryStringMap(String url)
    {
        Map<String, String> map = new HashMap<>();

        if (StringUtils.isNotBlank(url))
        {
            String[] split = url.split("#");

            if(split != null && split.length == 2 && StringUtils.isNotBlank(split[1]))
            {
                String[] params = split[1].split("&");

                if (params != null && params.length > 0)
                {
                    for (String param : params)
                    {
                        String[] working = param.split("=");

                        if (working != null && working.length >= 1 && StringUtils.isNotBlank(working[0]))
                        {
                            map.put(working[0], ((working.length == 2 && StringUtils.isNotBlank(working[1])) ? working[1] : ""));
                        }
                    }
                }
            }
        }

        return map;
    }

    private String getPublicKey()
    {
        String key = null;

        try
        {
            //Create HTTP Client that allows any ssl cert
            SSLContext sslContext = new SSLContextBuilder()
                .loadTrustMaterial(null, (certificate, authType) -> true).build();
            
            CloseableHttpClient httpClient = HttpClients.custom()
                .setSSLContext(sslContext)
                .setSSLHostnameVerifier(new NoopHostnameVerifier())
                .build();

            //Get realm details
            HttpGet httpGet = new HttpGet("https://" + getHostname() + "/auth/realms/" + getRealm() + "/");

            CloseableHttpResponse response = httpClient.execute(httpGet);
            HttpEntity entity = response.getEntity();
            
            BufferedReader in = new BufferedReader(
            new InputStreamReader(entity.getContent()));
            String inputLine;
            StringBuffer content = new StringBuffer();
            while ((inputLine = in.readLine()) != null)
            {
                content.append(inputLine);
            }
            in.close();

            //close HTTP Client
            httpClient.close();
            
            //Parse Response
            Type type = new TypeToken<Map<String, String>>(){}.getType();
            Gson gson = new Gson();
            Map<String, String> responseMap = gson.fromJson(content.toString(), type);

            if (responseMap.containsKey(TokenTestConstants.KEY_PUBLIC_KEY))
            {
                key = responseMap.get(TokenTestConstants.KEY_PUBLIC_KEY);
            }
        }
        catch (KeyStoreException | KeyManagementException | NoSuchAlgorithmException | IOException exception)
        {
            logger.info("Unable to get public key: " + exception.getMessage());
        }

        return key;
    }

    private String getHostname()
    {
        return resolveProperty(PROP_KEYCLOAK_HOSTNAME);
    }

    /**
     * Return who we expect to have created and sigend the token.
     * 
     * If not provied in the the environment or properties file we will attempt to build it from the hostname and realm
     * 
     * @return
     */
    private String getIssuer()
    {
        String keycloak_issuer = resolveProperty(PROP_KEYCLOAK_ISSUER);
        
        if (StringUtils.isEmpty(keycloak_issuer))
        {
            keycloak_issuer = buildIssuer(getHostname(), getRealm());
        }

        return keycloak_issuer;
    }

    private String getRealm()
    {
        return resolveProperty(PROP_KEYCLOAK_REALM);
    }

    private String getUser()
    {
        return resolveProperty(PROP_SAML_USERNAME);
    }

    private String getTheme()
    {
        return resolveProperty(PROP_KEYCLOAK_THEME);
    }

    private String getPassword()
    {
        return resolveProperty(PROP_SAML_PASSWORD);
    }

    /**
     * Return property value
     * <BR>
     * Values can be overridden from environment variables. In this case the following naming convention applies:
     * <P>
     * <code>property.name (property) -> PROPERTY_NAME (environment variable)</code>
     *
     * @param propertyName property name
     * @return property value
     */
    private String resolveProperty(String propertyName)
    {
        String envVarName = propertyName.replace(".", "_").toUpperCase();
        String propertyValue = System.getenv(envVarName);

        if (StringUtils.isEmpty(propertyValue))
        {
            propertyValue = appProps.getProperty(propertyName);
        }

        return propertyValue;
    }

    private Boolean isBrowserEnable()
    { 
        String enabled = appProps.getProperty(TokenTestConstants.PROP_ENABLE_BROWSER);
        
        if (StringUtils.isNotBlank(enabled))
        {
            return Boolean.valueOf(enabled);
        }

        return false;
    }

    private String buildIssuer(String hostname, String realm)
    {
        if (StringUtils.isNotEmpty(hostname) && StringUtils.isNotEmpty(realm))
        {
            return "https://" + hostname + "/auth/realms/" + realm;
        }

        return "";
    }
    
}
package org.alfresco.identity.service.saml.test;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import io.github.bonigarcia.wdm.WebDriverManager;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.io.FileUtils;
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
import org.openqa.selenium.By.ByName;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.net.ssl.SSLContext;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.security.KeyFactory;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

import static org.alfresco.identity.service.saml.test.TokenTestConstants.*;
import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * @author Jared Ottley
 */
@TestInstance(Lifecycle.PER_CLASS)
public class TokenTest
{
    private final Logger logger = LoggerFactory.getLogger(TokenTest.class);

    private Properties appProps = null;
    private WebDriver  driver;

    @BeforeAll
    void setup()
    {
        try
        {
            String rootPath = Objects.requireNonNull(Thread.currentThread()
                        .getContextClassLoader()
                        .getResource(""))
                        .getPath();
            String appConfigPath = rootPath + "application.properties";

            appProps = new Properties();
            appProps.load(new FileInputStream(appConfigPath));
        }
        catch (IOException exception)
        {
            logger.info("Unable to read properties file");
        }
        driver = createWebDriver();
    }

    public WebDriver createWebDriver()
    {
        return createChromeWebDriver();
    }

    private WebDriver createChromeWebDriver()
    {
            WebDriverManager.chromedriver()
                        .setup();
        return new ChromeDriver(getChromeOptions());
    }

    private ChromeOptions getChromeOptions()
    {
        ChromeOptions chromeOptions = new ChromeOptions();
        chromeOptions.setAcceptInsecureCerts(true);
        chromeOptions.addArguments("--no-sandbox");
        chromeOptions.addArguments("--disable-gpu");
        chromeOptions.addArguments("--disable-dev-shm-usage");
        chromeOptions.addArguments("--disable-extensions");
        chromeOptions.addArguments("--single-process");
        chromeOptions.addArguments("--headless");
        chromeOptions.addArguments("--test-type");
        chromeOptions.addArguments("--start-maximized");
        chromeOptions.addArguments("--disable-web-security");
        chromeOptions.addArguments("--allow-running-insecure-content");
        chromeOptions.addArguments("--disable-popup-blocking");
        chromeOptions.addArguments("--allow-insecure-localhost");
        chromeOptions.addArguments("--ignore-ssl-errors=yes");
        chromeOptions.addArguments("--ignore-certificate-errors");
        chromeOptions.setExperimentalOption("excludeSwitches", new String[] { "enable-automation" });
        // chromeOptions.addArguments(String.format("--lang=%s", getBrowserLanguage(properties)));
        //disable profile password manager
        HashMap<String, Object> chromePrefs = new HashMap<>();
        chromePrefs.put("credentials_enable_service", false);
        chromePrefs.put("profile.password_manager_enabled", false);
        // chromePrefs.put("download.default_directory", getDownloadLocation());
        chromeOptions.setExperimentalOption("prefs", chromePrefs);
        return chromeOptions;
    }

    @AfterAll
    void cleanup()
    {
        //Clean up remote chromedriver service
        if (driver != null)
        {
            driver.quit();
        }
    }

    @Test
    void getTokenFromSAMLLogin() throws Exception
    {
        //Increase Default Timeout for pages to load
        driver.manage()
                    .timeouts()
                    .implicitlyWait(10, TimeUnit.SECONDS);

        //Initiate page
        driver.get(getBaseUrl() + "/auth/realms/" + getRealm()
                               + "/protocol/openid-connect/auth?response_type=id_token%20token&client_id=alfresco&state=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs&redirect_uri="
                               + getBaseUrl()
                               + "/dummy_redirect&scope=openid%20profile%20email&nonce=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs");

        logger.info("Login page URL: " + driver.getCurrentUrl());
        //Click on SAML link on login page, the link is theme-dependent
        String themeName = getTheme();
        WebElement element = driver.findElement(
                    themeName.compareTo(ALFRESCO_THEME_NAME) == 0 ? ELEMENT_SAML_ALFRESCO : ELEMENT_SAML_KEYCLOAK);
        element.click();

        //Select User, Enter password, and submit form on SAML page
        WebElement usernameField = driver.findElement(ByName.name(TokenTestConstants.ELEMENT_USERID));
        usernameField.sendKeys(getUser());
        WebElement passwordField = driver.findElement(ByName.name(TokenTestConstants.ELEMENT_PASWORD));
        passwordField.sendKeys(getPassword());
        passwordField.submit();

        // Workaround to get the tests passing when using 'http' rather than 'https' protocol
        Thread.sleep(3000L);

        //Get the redirect URL for validation -- If you check the status of the
        //redirct URL call it will be 404.  The page does not exist. All we are
        //interested in is the token parameter in the URL
        logger.info("Redirect URL: " + driver.getCurrentUrl());
        logger.info("Page title: " + driver.getTitle());

        // Take a screenshot and save it to a file
        File screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);

        // Specify the destination file
        File destinationFile = new File("screenshot.png");

        // Copy the screenshot to the destination file
        FileUtils.copyFile(screenshot, destinationFile);

        logger.info("Screenshot saved at: " + destinationFile.getAbsolutePath());

        //Get token param
        Map<String, String> params = getQueryStringMap(driver.getCurrentUrl());
        logger.info("URL Params: " + params);

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
            logger.info("Payload Decoded: " + new String(Base64.decodeBase64(jwt.getPayload()
                                                                                         .getBytes())));
        }
        catch (JWTVerificationException exception)
        {
            logger.info("Verification failed");
        }

        assertNotNull(jwt);
    }

    //Utility Methods
    private Map<String, String> getQueryStringMap(String url)
    {
        Map<String, String> map = new HashMap<>();

        if (StringUtils.isNotBlank(url))
        {
            String[] split = url.split("#");

            if (split.length == 2 && StringUtils.isNotBlank(split[1]))
            {
                String[] params = split[1].split("&");

                if (params.length > 0)
                {
                    for (String param : params)
                    {
                        String[] working = param.split("=");

                        if (working.length >= 1 && StringUtils.isNotBlank(working[0]))
                        {
                            map.put(working[0],
                                    ((working.length == 2 && StringUtils.isNotBlank(working[1])) ? working[1] : ""));
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
            SSLContext sslContext = new SSLContextBuilder().loadTrustMaterial(null, (certificate, authType) -> true)
                        .build();

            CloseableHttpClient httpClient = HttpClients.custom()
                        .setSSLContext(sslContext)
                        .setSSLHostnameVerifier(new NoopHostnameVerifier())
                        .build();

            //Get realm details
            HttpGet httpGet = new HttpGet(getBaseUrl() + "/auth/realms/" + getRealm() + "/");

            CloseableHttpResponse response = httpClient.execute(httpGet);
            HttpEntity entity = response.getEntity();

            BufferedReader in = new BufferedReader(new InputStreamReader(entity.getContent()));
            String inputLine;
            StringBuilder content = new StringBuilder();
            while ((inputLine = in.readLine()) != null)
            {
                content.append(inputLine);
            }
            in.close();

            //close HTTP Client
            httpClient.close();

            //Parse Response
            Type type = new TypeToken<Map<String, String>>()
            {
            }.getType();
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

    private String getProtocol()
    {
        return resolveProperty(PROP_KEYCLOAK_PROTOCOL);
    }

    private String getHostname()
    {
        return resolveProperty(PROP_KEYCLOAK_HOSTNAME);
    }

    private String getPort()
    {
        String port = resolveProperty(PROP_KEYCLOAK_PORT);
        return Integer.parseInt(port) == 80 ? "" : ":" + port;
    }

    private String getBaseUrl()
    {
        String url = getProtocol() + "://" + getHostname() + getPort();
        logger.info("Base URL: " + url);
        return url;
    }

    /**
     * Return who we expect to have created and sigend the token.
     * If not provided in the the environment or properties file we will attempt to build it from the hostname and realm
     */
    private String getIssuer()
    {
        String keycloak_issuer = resolveProperty(PROP_KEYCLOAK_ISSUER);

        if (StringUtils.isEmpty(keycloak_issuer))
        {
            keycloak_issuer = buildIssuer();
        }

        return keycloak_issuer;
    }

    private String getRealm()
    {
        return resolveProperty(PROP_KEYCLOAK_REALM);
    }

    private String getUser()
    {
        return resolveProperty(SAML_USERNAME);
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
     * Values can be overridden from environment variables and Java properties. In this case the following naming convention applies:
     * <p>
     * <code>property.name (property) -> PROPERTY_NAME (environment variable)</code>
     *
     * @param propertyName property name
     * @return property value
     */
    private String resolveProperty(String propertyName)
    {
        String envVarName = propertyName.replace(".", "_")
                    .toUpperCase();
        String propertyValue = System.getenv(envVarName);
        if (StringUtils.isEmpty(propertyValue))
        {
            // Check Java properties too
            propertyValue = System.getProperty(propertyName);

            if (StringUtils.isEmpty(propertyValue))
            {
                propertyValue = appProps.getProperty(propertyName);
            }
        }

        return propertyValue;
    }

    private String buildIssuer()
    {
        if (StringUtils.isNotEmpty(getHostname()) && StringUtils.isNotEmpty(getRealm()))
        {
            return getBaseUrl() + "/auth/realms/" + getRealm();
        }
        return "";
    }
}

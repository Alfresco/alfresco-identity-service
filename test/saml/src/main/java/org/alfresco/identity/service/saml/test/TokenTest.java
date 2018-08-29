package org.alfresco.identity.service.saml.test;

import java.io.IOException;
import java.net.MalformedURLException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.HashMap;
import java.util.Map;

import com.auth0.jwt.JWT;
import com.auth0.jwt.exceptions.JWTDecodeException;
import com.auth0.jwt.interfaces.DecodedJWT;

import org.openqa.selenium.By.ByLinkText;
import org.openqa.selenium.By.ByName;
import org.apache.commons.codec.binary.Base64;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.htmlunit.HtmlUnitDriver;
import org.openqa.selenium.support.ui.Select;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class TokenTest
{  
    private Logger logger = LoggerFactory.getLogger(TokenTest.class);
    //Until this can read from a properties file or take a value from the environment or command line change
    private String hostname = "localhost";

    @EventListener(ApplicationReadyEvent.class)
    public void getTokenFromSAMLLogin() 
    throws MalformedURLException, 
           IOException, 
           NoSuchAlgorithmException, 
           InvalidKeySpecException, 
           Exception
    {
        //Create HTMLUnit WebDriver
        WebDriver driver = new HtmlUnitDriver(true);
        
        //Initiate page
        driver.get("https://" + hostname + "/auth/realms/alfresco/protocol/openid-connect/auth?response_type=id_token%20token&client_id=alfresco&state=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs&redirect_uri=http%3A%2F%2Flocalhost%2Fdummy_redirect&scope=openid%20profile%20email&nonce=CIteJYtFrA22JnCikKHJ2QPrNuGHzyOphE1SsSNs");
       
        //Click on SAML link on login page
        WebElement element = driver.findElement(ByLinkText.linkText("saml"));
        element.click();

        //Select User, Enter password, and submit form on SAML page
        Select select = new Select(driver.findElement(ByName.name("userid")));
        select.selectByVisibleText("userA");
        WebElement passwordfield = driver.findElement(ByName.name("password"));
        passwordfield.sendKeys("password");
        passwordfield.submit();

        //Get the redirect URL for validation -- If you check the status of the
        //redirct URL call it will be 404.  The page does not exist. All we are
        //intersted in is the token parameter in the URL
        logger.info("Redirect URL: " + driver.getCurrentUrl());

        //Get token param
        Map<String, String> params = getQueryStringMap(driver.getCurrentUrl());
        logger.info("access_token parameter: " + params.get("access_token"));
        String token = params.get("access_token");

        //Decode token
        try
        {
            DecodedJWT jwt = JWT.decode(token);
            logger.info("Payload Decoded: " + new String(Base64.decodeBase64(jwt.getPayload().getBytes())));

        }
        catch (JWTDecodeException exception)
        {
            //Invalid token
        }
        
        //Quit Driver session
        driver.quit();
    }


    private Map<String, String> getQueryStringMap(String url)
    {
        Map<String, String> map = new HashMap<>();

        //TODO add checks to make sure that the param is not null. Also check that
        //the split string is not null
        String[] split = url.split("#");

        //TODO add null checks
        String[] params = split[1].split("&");
        for (String param : params)
        {
            //TODO add check for '='
            String[] working = param.split("=");
            map.put(working[0], working[1]);
        }

        return map;
    }
    
}
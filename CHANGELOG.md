
## Release Notes - Identity Service

---
### *Alfresco Identity Service 1.1*

#### Stories


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-200'>AUTH-200</a>] - Provide a means to deploy the Identity Service with neither Docker nor Kubernetes



#### Bugs


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-213'>AUTH-213</a>] - Deprecated clientTemplates configuration in Alfresco realm

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-217'>AUTH-217</a>] - Web origins in overridden realm

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-227'>AUTH-227</a>] - SAML login button doesn't appear when using Alfresco login theme



#### Tasks


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-246'>AUTH-246</a>] - Upgrade to Keycloak 4.8.3.Final

---

### *Alfresco Identity Service 1.0*

#### Epics


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-134'>AUTH-134</a>] - Identity Service 1.0



#### Stories


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-130'>AUTH-130</a>] - Make Alfresco-Identity-Service Github repo public

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-148'>AUTH-148</a>] - Custom Alfresco Login Theme

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-149'>AUTH-149</a>] - Identify All Artifacts that need to be localized

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-150'>AUTH-150</a>] - Document instructions for configuring LDAP sync

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-151'>AUTH-151</a>] - Test LDAP sync

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-153'>AUTH-153</a>] - Document instructions for configuring SAML

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-154'>AUTH-154</a>] - Compliance with Alfresco Security Policy

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-155'>AUTH-155</a>] - Complete and Update Documentation for Deploying the Identity Service

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-158'>AUTH-158</a>] - Publish Artifacts

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-160'>AUTH-160</a>] - Release Notes

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-162'>AUTH-162</a>] - Automate regression testing for LDAP Authentication

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-184'>AUTH-184</a>] - Create a list of 3rd Party Software Dependencies

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-193'>AUTH-193</a>] - Stable Infrastructure Chart (with Identity Service)



#### Bugs


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-120'>AUTH-120</a>] - Pass the secret name as values to identity service 0.2 helm chart

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-152'>AUTH-152</a>] - ACS6: New identity-service authentication sub-system can freeze server

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-171'>AUTH-171</a>] - Token request with SAML provider results with &quot;upstream sent too big header&quot;

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-172'>AUTH-172</a>] - Identity Service Ingress is Broken Due to Truncation Differences

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-178'>AUTH-178</a>] - Empty Realm in Identity Service

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-183'>AUTH-183</a>] - Keycloak stateful sets are left over after &quot;helm delete&quot;

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-189'>AUTH-189</a>] - Keycloak PostgreSQL startup error when using helm upgrade

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-198'>AUTH-198</a>] - Error message overflows login box

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-207'>AUTH-207</a>] - APS http redirect_uri parameter for https-only requests

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-211'>AUTH-211</a>] - Error pages don&#39;t render correctly



#### Tasks


* [<a href='https://issues.alfresco.com/jira/browse/AUTH-17'>AUTH-17</a>] - A proof of concept that shows how to consume an identity token across several components of the platforms

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-25'>AUTH-25</a>] - Design user token that will be used to represent the logged in user

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-26'>AUTH-26</a>] - A proof of concept that shows how to consume an identity token across several components of the platforms

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-41'>AUTH-41</a>] - A proof of concept that shows how to consume an identity token across several components of the platforms

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-64'>AUTH-64</a>] - Integrate code into ACS to implement the use of the internal auth token

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-67'>AUTH-67</a>] - Ensure Keycloak Realm is Configurable at Deploy Time

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-68'>AUTH-68</a>] - Use the Official Keycloak Helm Chart

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-85'>AUTH-85</a>] - Move SSO token implementation back to Alfresco Community

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-94'>AUTH-94</a>] - Identity Service (Keycloak) Persistence

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-97'>AUTH-97</a>] - CLONE - Ensure Keycloak Realm is Configurable at Deploy Time

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-106'>AUTH-106</a>] - Automated testing of SSO for APS and ACS

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-118'>AUTH-118</a>] - Update infrastructure to use the Alfresco-identity service

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-119'>AUTH-119</a>] - Automate regression testing for SAML testing

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-121'>AUTH-121</a>] - Enable Automated Testing for SSO

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-126'>AUTH-126</a>] - DBP Postman tests refactoring

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-142'>AUTH-142</a>] - Update Identity Service description

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-143'>AUTH-143</a>] - Separate Test Cases for Authorization

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-175'>AUTH-175</a>] - Update Identity Service to latest Version of Keycloak Chart

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-194'>AUTH-194</a>] - Re-enable Postgres in Identity Service

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-195'>AUTH-195</a>] - Update the Alfresco Keycloak theme with messages translated by Alfresco

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-199'>AUTH-199</a>] - Remove the &quot;Need Help&quot; link in Alfresco Theme login

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-204'>AUTH-204</a>] - Update Identity Service to use version 4.5.0.Final

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-205'>AUTH-205</a>] - Test Identity Service Logout

* [<a href='https://issues.alfresco.com/jira/browse/AUTH-206'>AUTH-206</a>] - Document Keycloak deployment scenario



# Alfresco Identity Service

The Identity Service allows you to configure user synchronization between a supported LDAP provider or SAML identity provider and the Identity Service for Single Sign On (SSO) capabilities in other Alfresco software.

This project contains the open-source core of this service.

## Deploying the Identity Service
The steps in [Deploying the Identity Service](docs/deploy/is-deploy.md) detail how to deploy the Identity Service into an existing cluster. These steps use a set of default deployment options that can be customized by reading [Customizing an Identity Service deployment](docs/deploy/is-customize.md). It is recommended that you read through the customization options before starting your deployment.

## Configuring identity providers 
Once you have deployed the Identity Service, you can configure your user synchronization with an LDAP instance or setup an existing identity provider to authenticate with the Identity Service.

An example setup has been provided for configuring the Identity Service with a SAML 2.0 identity provider: [PingFederate](docs/config/ping-federate-example.md).

An example setup of user synchronization with an LDAP instance has been provided using [OpenLDAP](docs/config/openldap-example.md).

## Configuring Alfresco products
After deploying the Identity Service and configuring your existing identity provider with it, you will need to configure the properties for Alfresco Content Services and/or Alfresco Process Services to use the Identity Service for authentication.

## Contributing to Identity Service
We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

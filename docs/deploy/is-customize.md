# Customizing an Identity Service deployment

## Increasing resilience
There are a number of options for increasing the availability and resilience of a deployment.

### Replicas
During deployment you can specify multiple replicas to increase the resilience of an Identity Service deployment.

To enable multiple replicas, use the following command during the Helm chart deployment:

```bash
--set alfresco-infrastructure.alfresco-identity-service.keycloak.keycloak.replicas=3
```

### Clustering

Clustering is another method that can be used to increase the resilience of a deployment. Information on how to configure clustering is available in the following locations:


* [High availability and clustering](https://github.com/helm/charts/tree/master/stable/keycloak#high-availability-and-clustering)


* [Standalone clustered mode](https://www.keycloak.org/docs/4.5/server_installation/#standalone-clustered-configuration)


* [Clustering](https://www.keycloak.org/docs/4.5/server_installation/#_clustering)


**Note:** Keycloak recommends that [sticky sessions](https://www.keycloak.org/docs/4.5/server_installation/#sticky-sessions) are used, so be aware if you are using an ingress other than Nginx.

## Client and realm customization
It is possible to override some parameters set for the default realm and clients during and post-deployment.

### Client redirect URIs

The default redirect URI set during deployment is: `http://localhost*`. Using the `alfresco-identity-service.client.alfresco.redirectUris` property, you can specify a different redirect URI similar to the following example:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.client.alfresco.redirectUris=['\"'http://$DNSNAME*'"\'] \
  --namespace $DESIREDNAMESPACE
```

It is also possible to specify multiple redirect URIs using the same property:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.redirectUris=['\"'http://$DNSNAME*'"\'',''\"'http://$DNSNAME1*'"\'',''\"'http://$DNSNAME2*'"\']` \
  --namespace $DESIREDNAMESPACE
```

### Customizing the realm
You can customize a realm during the deployment process or manually in the administration console after you have deployed the Identity Service.

#### Realm customization during deployment
The following steps advise how to add a realm file to your deployment that contains details of its configuration.

1. Create a realm file. A [sample realm](../../helm/alfresco-identity-service/alfresco-realm.json) file is contained in this project.

2. Create a secret using your realm json file:

	```bash
	kubectl create secret generic realm-secret \
  	--from-file=./realm.json \
  	--namespace=$DESIREDNAMESPACE
	```

	**Note:** The name of the secret must be realm-secret and the name of the realm file must **not** be alfresco-realm.json.

3. Deploy the identity chart with the additional parameters:

	```bash
	helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable

	helm install alfresco-stable/alfresco-infrastructure \
  	--set alfresco-infrastructure.activemq.enabled=false \
  	--set alfresco-infrastructure.nginx-ingress.enabled=true \
  	--set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  	--set alfresco-infrastructure.alfresco-identity-service.keycloak.keycloak.extraArgs="-Dkeycloak.import=/realm/realm.json" \
  	--namespace $DESIREDNAMESPACE
	```

4. Once the deployment has finished, sign in to the [Management Console](http://www.keycloak.org/docs/4.5/server_admin/index.html#admin-console) to configure your new realm.

#### Manually customize a realm post-deployment
The following steps describe how to add a new realm manually post-deployment.

1. Open the administration console and [add a new realm](http://www.keycloak.org/docs/4.5/server_admin/index.html#_create-realm) called *Alfresco*.

2. [Create an OIDC client](http://www.keycloak.org/docs/4.5/server_admin/index.html#oidc-clients) called *alfresco* within the Alfresco realm you created in Step 1.

3. [Create a group](http://www.keycloak.org/docs/4.5/server_admin/index.html#groups) called *admin*.

4. [Add a new user](http://www.keycloak.org/docs/4.5/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test".

#### Manually import a realm file post-deployment
The following steps explain how to import a realm file post-deployment.

1. Create a realm file based on the [sample realm file](../../helm/alfresco-identity-service/alfresco-realm.json) provided in this project, or just use the sample file as it is.

2. Open the administration console and [add a new realm](http://www.keycloak.org/docs/4.5/server_admin/index.html#_create-realm). On the details page choose the **Select File** option and import your realm file, then click **Create**.

# Alfresco Identity Service

The *Alfresco Identity Service* will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication. This project contains the open-source core of this service.

Check [prerequisites section](https://github.com/Alfresco/alfresco-dbp-deployment/blob/master/README-prerequisite.md) before you start.

Any variation from these technologies and versions may affect the end result. If you do experience any issues please let us know through our [Gitter channel](https://gitter.im/Alfresco/platform-services?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

For installing and upgrading the Identity Service you can choose Kubernetes or the distribution zip. Both methods are described in the following paragraphs.

### Standalone Distribution

#### Overview
This guide helps you get started with the Identity Service. It covers simple standalone startup and use of the default database. Advanced deployment options are not covered. For a deeper description of Keycloak features or configuration options, consult the official [Keycloak readme](https://www.keycloak.org/docs/) .

#### Installing and booting

  1. Download the Identity Service zip alfresco-identity-service-1.2.0.zip from the Support Portal at http://support.alfresco.com

  2. Place the file in a directory you choose and use the unzip utility to extract it.

  Linux/Unix
  ```bash
  $ unzip alfresco-identity-service-1.2.0.zip
  ```

  Windows
  ```bash
  > unzip alfresco-identity-service-1.2.0.zip
  ```

  3. Cd to the bin directory of the server distribution and run the standalone boot script.

  Linux/Unix
  ```bash
  $ cd alfresco-identity-service-1.2.0/bin
  $ ./standalone.sh -b <IP_ADDRESS>
  ```
  Windows bat
  ```bash
  > ...\alfresco-identity-service-1.2.0\bin\standalone.bat -b <IP_ADDRESS>
  ```
  Windows powershell
  ```bash
  > ...\alfresco-identity-service-1.2.0\bin\standalone.ps1 -b <IP_ADDRESS>
  ```
  **_NOTE:_** To bind to all public interfaces use `0.0.0.0` as the value of IP_ADDRESS otherwise specify the the address of the specific interface you want to use.

This is deployed with the **default example realm applied** which results in default values of:

| Property                      | Value                    |
| ----------------------------- | ------------------------ |
| Admin User Username           | `admin`                  |
| Admin User Password           | `admin`                  |
| Admin User Email              | `admin@app.activiti.com` |
| Alfresco Client Redirect URIs | `*`      |

#### Creating the Master Realm Admin Account

After the server boots, open http://localhost:8080/auth in your web browser. The welcome page will indicate that the server is running.

Enter a username and password to create an initial admin user.

This account will be permitted to log in to the master realm’s administration console, from which you will create realms and users and register applications to be secured by Keycloak.

The Alfresco realm already has the admin account created and you can reach the realm console with the following url:

http://localhost:8080/auth/admin/alfresco/console/

#### Modifying the valid redirect URIs

  1. After logging in to the Alfresco realm follow the left side menu and choose clients.
  2. Choose the Afresco client from the client list.
  3. In the client settings window you will have to fill in your appropiate redirect URI's for the Content and Process applications.

### Kubernetes Deployment

### Kubernetes Cluster

These instructions illustrate deployment to a Kubernetes cluster on AWS.

Please check the Anaxes Shipyard documentation on [running a cluster](https://github.com/Alfresco/alfresco-anaxes-shipyard/blob/master/docs/running-a-cluster.md).

If you are deploying the Identity Service into a cluster with other Alfresco components such as Content Services and Process Services, a VPC and cluster with 5 nodes is recommended. Each node should be a m4.xlarge EC2 instance.

### Helm Tiller

Initialize the Helm Tiller:

```bash
helm init
```

### K8s Cluster Namespace

As mentioned as part of the Anaxes Shipyard guidelines, you should deploy into a separate namespace in the cluster to avoid conflicts (create the namespace only if it does not already exist):

```bash
export DESIREDNAMESPACE=example
kubectl create namespace $DESIREDNAMESPACE
```

This environment variable will be used in the deployment steps.

## Deploying the Identity Services Chart

1. In order to deploy this chart you have to deploy the [Alfresco Infrastructure chart](https://github.com/Alfresco/alfresco-infrastructure-deployment#1-deploy-the-infrastructure-charts) which will deploy the Identity Service too.

Using the following command only the Identity Service and the [nginx-ingress](https://github.com/Alfresco/alfresco-infrastructure-deployment#nginx-ingress-custom-configuration) will be deployed:

```bash

helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
helm repo add codecentric https://codecentric.github.io/helm-charts

helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --namespace $DESIREDNAMESPACE
```

<!-- markdownlint-disable MD029 -->
2. Get the release name from the previous command and set it as a variable:
<!-- markdownlint-disable MD029 -->

```bash
export RELEASENAME=knobby-wolf
```

<!-- markdownlint-disable MD029 -->
3. Wait for the release to get deployed (When checking status your pods should be READY 1/1):
<!-- markdownlint-enable MD029 -->

```bash
helm status $RELEASENAME
```

<!-- markdownlint-disable MD029 -->
4. Get local or ELB IP and set it as a variable for future use:
<!-- markdownlint-disable MD029 -->

```bash
export ELBADDRESS=$(kubectl get services $RELEASENAME-nginx-ingress-controller --namespace=$DESIREDNAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

The deployment 

This is deployed with the **default example realm applied** which results in default values of:

| Property                      | Value                    |
| ----------------------------- | ------------------------ |
| Admin User Username           | `admin`                  |
| Admin User Password           | `admin`                  |
| Admin User Email              | `admin@app.activiti.com` |
| Alfresco Client Redirect URIs | `http://localhost*`      |

(Note that APS expects the email as the user name)

#### Changing Alfresco Client redirectUris

You can override the default redirectUri of `http://localhost*` for your environment with the `alfresco-identity-service.client.alfresco.redirectUris` property:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.realm.alfresco.client.redirectUris="{$DNSNAME}" \
  --namespace $DESIREDNAMESPACE
```

including multiple redirectUris:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.realm.alfresco.client.redirectUris="{$DNSNAME,$DNSNAME1,$DNSNAME2}" \
  --namespace $DESIREDNAMESPACE
```

Note in case of multiple redirectUris the values must be comma-separated with no whitespaces surrounding the 
corresponding commas. 

If you want to deploy your own realm with further customizations, see *Customizing the Realm* below.

#### Changing Alfresco Client webOrigins

Similarly to [redirectUris](#changing-alfresco-client-redirecturis), webOrigins can be changed by overriding the 
`alfresco-identity-service.client.alfresco.webOrigins` property:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.realm.alfresco.client.webOrigins="{$DNSNAME}" \
  --namespace $DESIREDNAMESPACE
```

For multiple webOrigins:

```bash
helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.realm.alfresco.client.webOrigins="{$DNSNAME,$DNSNAME1,$DNSNAME2}" \
  --namespace $DESIREDNAMESPACE
```

## Multiple Replicas, High Availability and Clustering

For added resilience, we rely on support in the Keycloak chart for specifying multiple replicas.  To enable this you will need to deploy the identity chart with this additional setting:

```bash

  --set alfresco-identity-service.keycloak.keycloak.replicas=3

```

In addition, for high availability, Keycloak supports clustering.  For more information on how to configure high availability and clustering, you can consult this additional documentation.  


[Keycloak Stable chart Readme](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak#high-availability-and-clustering)


[Keycloak Standalone Clustered configuration](https://www.keycloak.org/docs/7.0/server_installation/#standalone-clustered-configuration)


[Keycloak Clustering](https://www.keycloak.org/docs/7.0/server_installation/#_clustering)


**_NOTE:_** Be aware that Keycloak recommends that [sticky sessions](https://www.keycloak.org/docs/7.0/server_installation/#sticky-sessions) are used so keep that in mind if you choose to use a different ingress type than nginx.

## Customizing the Realm

### Customizing the Realm During Deployment

1. You will need a realm file. A [sample realm](./helm/alfresco-identity-service/alfresco-realm.json) file is provided.

2. Create a secret using your realm json file

**_!!NOTE_** The secret name must be realm-secret, and the realm file name must not be alfresco-realm.json.

```bash

kubectl create secret generic realm-secret \
  --from-file=./realm.json \
  --namespace=$DESIREDNAMESPACE
```


<!-- markdownlint-disable MD029 -->
3. Deploy the identity chart with the new settings:
<!-- markdownlint-enable MD029 -->

```bash

helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
helm repo add codecentric https://codecentric.github.io/helm-charts

helm install alfresco-stable/alfresco-infrastructure \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.keycloak.keycloak.extraArgs="-Dkeycloak.import=/realm/realm.json" \
  --namespace $DESIREDNAMESPACE
```

Once Keycloak is up and running, login to the [Management Console](http://www.keycloak.org/docs/7.0/server_admin/index.html#admin-console) to configure the required realm.

#### Manually

1. [Add a realm](http://www.keycloak.org/docs/7.0/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/7.0/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/7.0/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/7.0/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

#### Using the Sample Realm File

1. Go to the [Add Realm](http://www.keycloak.org/docs/7.0/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

2. Choose the [sample realm](./alfresco-realm.json) file and click the "Create" button.

## Upgrading from Identity Service 1.1 to 1.2

  **_NOTE:_** The upgrade of the Alfresco Identity Management Service requires downtime. 
  This means that no user will be able to connect to any of the Digital Business Platform components while the upgrade or rollback is being done.

### General upgrade procedure

For upgrading Alfresco Identity Management Service we are mainly following the Keycloak upgrade procedure.
We will be explaining how to do it if you are using our out of the box distribution or Kubernetes deployment.
However depending on the environment you are using you should follow these high-level steps:

1. Prior to applying the upgrade, [handle any open transactions](https://www.keycloak.org/docs/4.8/server_admin/#user-session-management) and delete the data/tx-object-store/ transaction directory.

2. Back up the old installation (configuration, themes, and so on).

3. Back up the database. For detailed information on how to back up the database, see the documentation for the relational database you are using.

4. Upgrade Keycloak server.

   - Testing the upgrade in a non-production environment first, to prevent any installation issues from being exposed in production, is a best practice.

   - Be aware that after the upgrade the database will no longer be compatible with the old server

   - Ensure the upgraded server is functional before upgrading adapters in production.

5. If you need to revert the upgrade, first restore the old installation, and then restore the database from the backup copy.

6. Upgrade the adapters.

Within the next sections we will go trough a simple distribution and Kubernetes upgrade plus rollback.

  **_NOTE:_** In depth documentation on Keycloak upgrade can be found [here](https://www.keycloak.org/docs/7.0/upgrading/index.html#_upgrading).

### Kubernetes

#### Generic Information

To do the upgrade in Kubernetes we are taking advantage of Kubernetes jobs and Helm hooks.

These are the steps we are following for a smooth upgrade transition without any manual intervention:

1. Pre-Upgrade job is running to remove the Keycloak statefulset, thus killing of any existent user session.
2. Pre-Upgrade job is running to create an extra volume for backing up the PostgreSQL database.
3. Pre-Upgrade job to do the backup of the database.
4. Pre-Upgrade job to delete the database deployment so that it does not clash with the new PostgreSQL deployment.
5. Post-Upgrade job to scale the new Keycloak to 0 replicas so we can restore the database initially.
6. Post-Upgrade job to restore the database data.
7. Post-Upgrade job to re-scale Keycloak back to 1 replica so that it can start using the new data.

This process leaves us with an additional volume containing the database backup.
That volume will be used in the case a rollback is done but will be deleted when the entire release is being deleted.

For the rollback process we are using the following jobs:

1. Pre-rollback job to kill off the current statefulsets.
2. Post-rollback job to scale Keycloak to 0 replicas.
3. Post-rollback job to restore the database from backup.
4. Post-rollback job to scale Keycloak to 1 replica.

#### How to upgrade

  **_NOTE:_** This upgrade works only from 1.1 to 1.2 version of the Alfresco Identity Management Service .

1. Identify your infrastructure chart deployment and save it in a variable.

```bash
export RELEASENAME=knobby-wolf
```

2. Run the helm upgrade command using the new version of the infrastructure chart that contains Alfresco Identity Management Service 1.2.
If you however have the Digital Business Platform Helm Chart installed you will need to upgrade to a newer DBP chart which containes Alfresco Identity Management Service 1.2.

```bash
helm upgrade $RELEASENAME alfresco-incubator/alfresco-infrastructure --version 5.2.0
```

3. A series of jobs will be running to do the upgrade after which you will be able to access the AIMS server at the same location. The AIMS service should be back up in a few minutes.

#### How to Rollback

1. If for any reason the upgrade to 1.2 failed or you just want to rollback to 1.1 issue the following command:

```bash
helm rollback --force --recreate-pods --cleanup-on-fail $RELEASENAME 1
```

The AIMS service will be back to it's original state in a few minutes.

### ZIP Distribution

#### Upgrade example for Identity Service with PostgreSQL database

1. Backup the old installation by performing:

```bash
pg_dump --clean --no-owner --no-acl -h ${POSTGRES_HOST} -p ${POSTGRES_PORT}  -U ${POSTGRES_USER} ${POSTGRES_DATABASE} | grep -v -E '(DROP\ SCHEMA\ public|CREATE\ SCHEMA\ public|COMMENT\ ON\ SCHEMA\ public|DROP\ EXTENSION\ plpgsql|CREATE\ EXTENSION\ IF\ NOT\ EXISTS\ plpgsql|COMMENT\ ON\ EXTENSION\ plpgsql)' > /backup/backup.sql
```
	
2. Remove old data and stop the PostgreSQL instance.

3. Stop the Identity Service 1.1 server.

4. Open Identity Service 1.2 distribution zip and configure accordingly to the database that will be used (for this example PostgreSQL).
   For detailed information on how to set up the desired database this visit the official documentation of Keycloak [here](https://www.keycloak.org/docs/4.8/server_installation/#_database).
   
5. Start the database and restore data by executing the following command:

```bash
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DATABASE} -U ${POSTGRES_USER} -f /backup/backup.sql
``` 

6. Start Identity Service 1.2 as described [above](installing-and-booting).

## Contributing to Identity Service

We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

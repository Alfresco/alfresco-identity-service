# Alfresco Identity Service

The *Alfresco Identity Service* will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication. This project contains the open-source core of this service.

For installing and [upgrading](https://github.com/Alfresco/alfresco-identity-service/blob/release/2.0.x/upgrade.md) the Identity Service you can choose either a Kubernetes distribution or a standalone distribution. Both methods are described in the following sections.

Check the [Kubernetes deployment prerequisites](https://github.com/Alfresco/alfresco-dbp-deployment/blob/master/README-prerequisite.md) and [standalone prerequisites](#prerequisites) before you start.

Any variation from these technologies and versions may affect the end result. If you do experience any issues please let us know through our [Gitter channel](https://gitter.im/Alfresco/identity-service?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

### Standalone Distribution

#### Overview
This guide helps you get started with the Identity Service. It covers simple standalone startup and use of the default database. Advanced deployment options are not covered. For a deeper description of Keycloak features or configuration options, consult the official [Keycloak readme](https://www.keycloak.org/docs) .

#### Prerequisites
  1. Java 11 JDK

#### Installing and booting

  1. Download the Identity Service zip alfresco-identity-service-2.0.0.zip from the Support Portal at http://support.alfresco.com

  2. Place the file in a directory you choose and use unzip utility to extract it.

  Linux/Unix
  ```bash
  $ unzip alfresco-identity-service-2.0.0.zip
  ```

  Windows
  ```bash
  > unzip alfresco-identity-service-2.0.0.zip
  ```

  3. Cd to the bin directory of the server distribution and run the standalone boot script.

  Linux/Unix
  ```bash
  $ cd alfresco-identity-service-2.0.0/bin
  $ ./kc.sh start --import-realm --http-relative-path="/auth" --hostname=<HOSTNAME> --https-certificate-file=<PATH_TO_CERT_FILE> --https-certificate-key-file=<PATH_TO_CERT_KEY_FILE>
  ```
  Windows bat
  ```bash
  > ...\alfresco-identity-service-2.0.0\bin\kc.bat start --import-realm --http-relative-path=/auth --hostname=<HOSTNAME> --https-certificate-file=<PATH_TO_CERT_FILE> --https-certificate-key-file=<PATH_TO_CERT_KEY_FILE>
  ```

This is deployed with the **default example realm applied** which results in default values of:

| Property                      | Value                    |
| ----------------------------- | ------------------------ |
| Admin User Username           | `admin`                  |
| Admin User Password           | `admin`                  |
| Admin User Email              | `admin@app.activiti.com` |
| Alfresco Client Redirect URIs | `*`      |

#### Creating the Master Realm Admin Account

After the server boots, open http://<IP_ADDRESS>:8080/auth in your web browser. The welcome page will indicate that the server is running.

Enter a username and password to create an initial admin user.

This account will be permitted to log in to the master realm’s administration console, from which you will create realms and users and register applications to be secured by Keycloak.


The Alfresco realm already has the admin account created and you can reach the realm console with the following url:

http://<IP_ADDRESS>:8080/auth/admin/alfresco/console/

#### Modifying the valid redirect URIs

**Note**: for security reasons, the redirect URIs should be as specific as possible. [See Keycloak official documentation](https://www.keycloak.org/docs/21.1.2/securing_apps/#redirect-uris).

  1. After logging in to the Alfresco realm follow the left side menu and choose clients.
  2. Choose the Alfresco client from the client list.
  3. In the client settings window you will have to fill in your appropriate redirect URI's for the Content and Process applications.

### Kubernetes Deployment

### Kubernetes Cluster

These instructions illustrate deployment to a Kubernetes cluster on EKS.

Please check the ACS deployment [documentation](https://github.com/Alfresco/acs-deployment/blob/master/docs/helm/eks-deployment.md).

If you are deploying the Identity Service into a cluster with other Alfresco components such as Content Services and Process Services, a VPC and cluster with 5 nodes is recommended. Each node should be a m4.xlarge EC2 instance.

### K8s Cluster Namespace

Create the namespace if it does not already exist, to avoid conflicts in the cluster:

```bash
export DESIREDNAMESPACE=example
kubectl create namespace $DESIREDNAMESPACE
```

This environment variable will be used in the deployment steps.

## Deploying the standalone Identity Services Chart

1. Prepare the EKS cluster by deploying an ingress. See the instruction [here](https://github.com/Alfresco/acs-deployment/blob/master/docs/helm/eks-deployment.md#ingress)


2. Get the release name from the ingress deployment (step 1) and set it as a variable:

```bash
export INGRESS_RELEASENAME=<YOUR_INGRESS_RELEASE_NAME>
```

3. Set the Identity Service release name as a variable:

```bash
export RELEASENAME=ids
```

4. Deploy the Identity Service.

```bash

helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable

helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
  --namespace $DESIREDNAMESPACE
```

<!-- markdownlint-disable MD029 -->
5. Wait for the release to get deployed (When checking status your pods should be READY 1/1):
<!-- markdownlint-enable MD029 -->

```bash
helm status $RELEASENAME
```

<!-- markdownlint-disable MD029 -->
6. Get local or ELB IP and set it as a variable for future use:
<!-- markdownlint-disable MD029 -->

```bash
export ELBADDRESS=$(kubectl get services $INGRESS_RELEASENAME-ingress-nginx-controller --namespace=$DESIREDNAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

The above steps will deploy _alfresco-identity-service_ with the **default example realm applied** which results in default values of:

| Property                      | Value                    |
| ----------------------------- | ------------------------ |
| Admin User Username           | `admin`                  |
| Admin User Password           | `admin`                  |
| Admin User Email              | `admin@app.activiti.com` |
| Alfresco Client Redirect URIs | `http://localhost*`      |

(Note that APS expects the email as the username)

#### Changing Alfresco Client redirectUris

**Note**: for security reasons, the redirect URIs should be as specific as possible. [See Keycloak official documentation](https://www.keycloak.org/docs/21.1.2/securing_apps/#redirect-uris).

You can override the default redirectUri of `http://localhost*` for your environment with the `alfresco-identity-service.client.alfresco.redirectUris` property:

```bash
helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
  --set alfresco-identity-service.realm.alfresco.client.redirectUris="{$DNSNAME}" \
  --namespace $DESIREDNAMESPACE
```

including multiple redirectUris:

```bash
helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
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
helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
  --set alfresco-identity-service.realm.alfresco.client.webOrigins="{$DNSNAME}" \
  --namespace $DESIREDNAMESPACE
```

For multiple webOrigins:

```bash
helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
  --set alfresco-identity-service.realm.alfresco.client.webOrigins="{$DNSNAME,$DNSNAME1,$DNSNAME2}" \
  --namespace $DESIREDNAMESPACE
```

## Multiple Replicas, High Availability and Clustering

For added resilience, we rely on support in the Keycloak chart for specifying multiple replicas.  To enable this you will need to deploy the identity chart with this additional setting:

```bash

  --set alfresco-identity-service.keycloakx.replicas=3

```

In addition, for high availability, Keycloak supports clustering.  For more information on how to configure high availability and clustering, you can consult this additional documentation.  


[Keycloak-X chart Readme](https://github.com/codecentric/helm-charts/blob/keycloakx-2.2.1/charts/keycloakx/README.md#high-availability-and-clustering)


[Configuring Keycloak for production](https://www.keycloak.org/server/configuration-production)

**_NOTE:_** Be aware that Keycloak recommends that [sticky sessions](https://www.keycloak.org/server/reverseproxy#_enable_sticky_sessions) are used so keep that in mind if you choose to use a different ingress type than nginx.

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

3. Create a yaml file with following settings. The file name can be anything, for example: **custom-values.yaml**

```yaml
keycloakx:
  extraEnv: |
    - name: KEYCLOAK_ADMIN
      value: admin
    - name: KEYCLOAK_ADMIN_PASSWORD
      value: admin
    - name: KEYCLOAK_IMPORT
      value: /data/import/alfresco-realm.json
    - name: JAVA_OPTS_APPEND
      value: >-
        -Djgroups.dns.query={{ include "keycloak.fullname" . }}-headless
```

**_NOTE:_** The above settings use the default _admin/admin_ for keycloak username and password, you can replace those with your own values.

<!-- markdownlint-disable MD029 -->
4. Deploy the identity chart with the new settings:
<!-- markdownlint-enable MD029 -->

```bash

helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable

helm install $RELEASENAME alfresco-stable/alfresco-identity-service --devel \
  -f custom-values.yaml \
  --namespace $DESIREDNAMESPACE
```

For further details see [Setting a Custom Realm](https://github.com/codecentric/helm-charts/tree/keycloak-18.0.0/charts/keycloak#setting-a-custom-realm).

Once Keycloak is up and running, login to the [Management Console](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#using-the-admin-console) to configure the required realm.

#### Manually

1. [Add a realm](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#proc-creating-a-realm_server_administration_guide) named "Alfresco"

2. [Create an OIDC client](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#_oidc_clients) named "alfresco" within the Alfresco realm

3. [Create a group](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#proc-managing-groups_server_administration_guide) named "admin"

4. [Add a new user](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#proc-creating-user_server_administration_guide) with a username of "testuser", email of "test@test.com" and first and last name of "test"

#### Using the Sample Realm File

1. Go to the [Add Realm](https://www.keycloak.org/docs/21.1.2/server_admin/index.html#proc-creating-a-realm_server_administration_guide) page and click the "Select File" button next to the **Import** label.

2. Choose the [sample realm](./alfresco-realm.json) file and click the "Create" button.

## Contributing to Identity Service

We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

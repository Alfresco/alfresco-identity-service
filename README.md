# Alfresco Identity Service

The *Alfresco Identity Service* will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication. This project contains the open-source core of this service.

## Prerequisites

The Alfresco Identity Service deployment requires:

| Component        | Recommended version |
| ------------- |:-------------:|
| Docker     | 17.0.9.1 |
| Kubernetes | 1.8.4    |
| Kubectl    | 1.8.4    |
| Helm       | 2.8.2    |
| Kops       | 1.8.1    |

Any variation from these technologies and versions may affect the end result. If you do experience any issues please let us know through our [Gitter channel](https://gitter.im/Alfresco/platform-services?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

### Kubernetes Cluster

These instructions illustrate deployment to a Kubernetes cluster on AWS.

Please check the Anaxes Shipyard documentation on [running a cluster](https://github.com/Alfresco/alfresco-anaxes-shipyard/blob/master/SECRETS.md).

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

1. In order to deploy this chart you have to deploy the [Alfresco Infrastructure chart](https://github.com/Alfresco/alfresco-infrastructure-deployment#1-deploy-the-infrastructure-charts) which will deploy the identity service too.

Using the following command only the identity service and the [nginx-ingress](https://github.com/Alfresco/alfresco-infrastructure-deployment#nginx-ingress-custom-configuration) will be deployed:

<!--TODO Change to stable alfresco-infrastructure that includes alfresco-identity-service AUTH-193-->
```bash

helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator
helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable


helm install alfresco-incubator/alfresco-infrastructure --version 3.0.0-SNAPSHOT \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --namespace $DESIREDNAMESPACE
```

<!-- markdownlint-disable MD029 -->
2. Get the release name from the previous command and set it as a varible:
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
4. Get Minikube or ELB IP and set it as a variable for future use:
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
helm install alfresco-incubator/alfresco-infrastructure --version 3.0.0-SNAPSHOT \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.client.alfresco.redirectUris=['\"'http://$DNSNAME*'"\'] \
  --namespace $DESIREDNAMESPACE
```

including multiple redirectUris:

```bash
helm install alfresco-incubator/alfresco-infrastructure --version 3.0.0-SNAPSHOT \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-identity-service.redirectUris=['\"'http://$DNSNAME*'"\'',''\"'http://$DNSNAME1*'"\'',''\"'http://$DNSNAME2*'"\']` \
  --namespace $DESIREDNAMESPACE
```

If you want to deploy your own realm with further customizations, see *Customizing the Realm* below.

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

helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator

helm install alfresco-incubator/alfresco-infrastructure --version 3.0.0-SNAPSHOT \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.keycloak.keycloak.extraArgs="-Dkeycloak.import=/realm/realm.json" \
  --namespace $DESIREDNAMESPACE
```

Once Keycloak is up and running, login to the [Management Console](http://www.keycloak.org/docs/3.4/server_admin/index.html#admin-console) to configure the required realm.

## High Availability and Clustering

For high availability we rely on the public implementation of the stable keycloak chart.
To enable this you will need to deploy the identity chart with the following settings:

```bash

helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator

helm install alfresco-incubator/alfresco-infrastructure --version 3.0.0-SNAPSHOT \
  --set alfresco-infrastructure.activemq.enabled=false \
  --set alfresco-infrastructure.nginx-ingress.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
  --set alfresco-infrastructure.alfresco-identity-service.keycloak.keycloak.extraArgs="-Dkeycloak.import=/realm/realm.json" \
  --set alfresco-infrastructure.alfresco-identity-service.keycloak.keycloak.replicas=3
  --namespace $DESIREDNAMESPACE
```

For more information on how Standalone High Availability works on keycloak please checkout:
[Keycloak stable chart Readme](https://github.com/helm/charts/tree/master/stable/keycloak#high-availability-and-clustering)
[Keycloak Standalone Clustered configuration](https://www.keycloak.org/docs/4.5/server_installation/#standalone-clustered-configuration)
[Keycloak Clustering](https://www.keycloak.org/docs/4.5/server_installation/#_clustering)

#### Manually

1. [Add a realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.4/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.4/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

#### Using the Sample Realm File

1. Go to the [Add Realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

2. Choose the [sample realm](./alfresco-realm.json) file and click the "Create" button.

## Contributing to Identity Service

We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

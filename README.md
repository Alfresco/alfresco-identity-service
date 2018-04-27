# Alfresco Identity Service

The Alfresco Identity Service provides a Single Sign On experience for the Alfresco Digital Business Platform (DBP).

The Identity Service is based on [Keycloak](http://www.keycloak.org) and provides a [sample realm](./alfresco-realm.json) file for use with the DBP.

## Prerequisites

The Alfresco Keycloak Deployment requires:

| Component        | Recommended version |
| ------------- |:-------------:|
| Docker     | 17.0.9.1 |
| Kubernetes | 1.8.0    |
| Helm       | 2.7.0    |
| Minikube   | 0.25.0   |

Any variation from these technologies and versions may affect the end result. If you do experience any issues please let us know through our [Gitter channel](https://gitter.im/Alfresco/platform-services?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

### Kubernetes Cluster

You can choose to deploy the infrastructure to a local kubernetes cluster (illustrated using minikube) or you can choose to deploy to the cloud (illustrated using AWS).
Please check the Anaxes Shipyard documentation on [running a cluster](https://github.com/Alfresco/alfresco-anaxes-shipyard/blob/master/SECRETS.md).

Note the resource requirements:
* Minikube: At least 2 gigs of memory, i.e.:
```bash
minikube start --memory 2000
```
* AWS: A VPC and cluster with 5 nodes. Each node should be a m4.xlarge EC2 instance.

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

## Deploying the Keycloak Chart

1. Install the nginx-ingress-controller into your cluster

```
helm repo update
helm install stable/nginx-ingress \
--version=0.12.3 \
--set controller.scope.enabled=true \
--set controller.scope.namespace=$DESIREDNAMESPACE \
--set controller.publishService.enabled=true \
--namespace $DESIREDNAMESPACE
```

### 2. Create a DNS entry your deployment:


```bash
#ON MINIKUBE
export ELBADDRESS=$(minikube ip)
echo "$ELBADDRESS minikube" >> /etc/hosts
```

```bash
#ON AWS (Optional if do not have one deployed already)
# Deploy an instance of external-dns stable chart with your hosted zone as a domain filter
helm install stable/external-dns \
--set domainFilters={"yourDNS.zone.com"} \
--set policy=sync \
--set sources={"ingress"} \
--namespace $DESIREDNAMESPACE
```

### 3. Generate a tls certificate for your dns entry:

```bash
#ON minikube
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=minikube"

#ON AWS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=application.yourDNS.zone.com"
```

### 4. Create a kubernetes secret with the generated keys:

```bash
kubectl create secret tls keycloak-secret --key /tmp/tls.key --cert /tmp/tls.crt 
--namespace=$DESIREDNAMESPACE
```

### 5. Deploy the keycloak charts:
```bash

helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator

#ON MINIKUBE
helm install alfresco-incubator/alfresco-identity-service \
--set keycloak.keycloak.ingress.hosts={"minikube"}
--namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
--set keycloak.keycloak.ingress.hosts={"application.yourDNS.zone.com"}
--namespace $DESIREDNAMESPACE
```

### Setup Keycloak with a SAML IdP provider

In order to create a SAML provider in Keycloak you will have to go to the Identity Providers left menu item and select SAML v2.0 from the Add provider drop down list. To configure it, you will have two options:

* You can manually fill the necessary fields in concordance with the settings of your SAML IdP

* Or the preferred way to configure it, would be to import your IdP metadata by providing the URL or import them as a file.

Once you have finished creating the Identity Provider in Keycloak you can export the SAML SP entity descriptor in order to import it into your external Service Provider. Depending on your configuration, the same metadata can be found here:

```bash
http[s]://{host:port}/auth/realms/{realm-name}/broker/{broker-alias}/endpoint/descriptor
```

More details in Keycloak's [documentation](https://www.keycloak.org/docs/3.4/server_admin/index.html#saml-v2-0-identity-providers)

## Configure Alfresco Realm

Once Keycloak is up and running login to the [Management Console](http://www.keycloak.org/docs/3.4/server_admin/index.html#admin-console) to configure the required realm, you can either do this manually or using the sample realm file.

### On kubernetes deploy time

1. You will need a realm json, similar to alfresco-realm.json

2. Create a secret using your realm json file

```bash

kubectl create secret generic realmsecret \
--from-file=./realm.json \
--namespace=$DESIREDNAMESPACE

export secretname=realmsecret
export secretkey=realm.json
```

3. Deploy the keycloak chart:

```bash

helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator

#ON MINIKUBE
helm install alfresco-incubator/alfresco-identity-service \
--set keycloak.keycloak.ingress.hosts={"minikube"}
--set keycloak.secretName=$secretname \
--set keycloak.secretKey=$secretkey \
--namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
--set keycloak.keycloak.ingress.hosts={"application.yourDNS.zone.com"}
--set keycloak.secretName=$secretname \
--set keycloak.secretKey=$secretkey \
--namespace $DESIREDNAMESPACE
```

### Manually

1. [Add a realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.4/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.4/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

### Sample Realm

Go to the [Add Realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

Choose the [alfresco-realm.json](./alfresco-realm.json) file and click the "Create" button.

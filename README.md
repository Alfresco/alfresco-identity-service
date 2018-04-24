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
## Deploying the Keycloak Chart

1. Install the nginx-ingress-controller
Install the nginx-ingress-controller into your cluster

```bash
helm repo update

cat <<EOF > ingressvalues.yaml
controller:
  config:
    ssl-redirect: "false"
  scope:
    enabled: true
    namespace: $DESIREDNAMESPACE
EOF

helm install stable/nginx-ingress --version=0.12.3 -f ingressvalues.yaml \
--namespace $DESIREDNAMESPACE
```

### 2. Deploy the keycloak charts:
```bash

helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator

#ON MINIKUBE
helm install alfresco-incubator/alfresco-identity-service \
--namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
--namespace $DESIREDNAMESPACE
```

## Customizing the keycloak Realm

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
--set keycloak.secretName=$secretname \
--set keycloak.secretKey=$secretkey \
--namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
--set keycloak.secretName=$secretname \
--set keycloak.secretKey=$secretkey \
--namespace $DESIREDNAMESPACE
```

### Manually

Once Keycloak is up and running login to the [Management Console](http://www.keycloak.org/docs/3.4/server_admin/index.html#admin-console) to configure the required realm, you can either do this manually or using the sample realm file.

1. [Add a realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.4/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.4/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

### Sample Realm

Go to the [Add Realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

Choose the [alfresco-realm.json](./alfresco-realm.json) file and click the "Create" button.
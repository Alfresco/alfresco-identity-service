# Alfresco Identity Service

The *Alfresco Identity Service* will become the central component responsible for identity-related capabilities needed by other Alfresco software, such as managing users, groups, roles, profiles, and authentication. Currently it deals just with authentication. This project contains the open-source core of this service.

## Prerequisites

The Alfresco Keycloak Deployment requires:

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

1. Install the nginx-ingress-controller into your cluster

    This will create a ELB when using AWS and will set a dummy certificate on it.

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

    *Optional*

    If you want your own certificate set here you should create a secret from your cert files:

    ```bash
    kubectl create secret tls certsecret --key /tmp/tls.key --cert /tmp/tls.crt --namespace $DESIREDNAMESPACE
    ```
    Then deploy the ingress with following settings
    ```bash
    cat <<EOF > ingressvalues.yaml
    controller:
      config:
        ssl-redirect: "false"
      scope:
        enabled: true
        namespace: $DESIREDNAMESPACE
      publishService:
        enabled: true
      extraArgs:
        default-ssl-certificate: $DESIREDNAMESPACE/certsecret
    EOF

    helm install stable/nginx-ingress --version=0.12.3 -f ingressvalues.yaml \
    --namespace $DESIREDNAMESPACE
    ```

    Or you can add an AWS generated certificate if you want and autogenerate a route53 entry

    ```bash
    cat <<EOF > ingressvalues.yaml
    controller:
      config:
        ssl-redirect: "false"
      scope:
        enabled: true
        namespace: $DESIREDNAMESPACE
      publishService:
        enabled: true
      service:
        targetPorts:
          https: 80
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-ssl-cert: #sslcert ARN -> https://github.com/kubernetes/kubernetes/blob/master/pkg/cloudprovider/providers/aws/aws.go
          service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
          # External dns will help you autogenerate an entry in route53 for your cluster. More info here -> https://github.com/kubernetes-incubator/external-dns
          external-dns.alpha.kubernetes.io/hostname: $DESIREDNAMESPACE.YourDNSZone
    EOF

    helm install stable/nginx-ingress --version=0.12.3 -f ingressvalues.yaml \
    --namespace $DESIREDNAMESPACE
    ```

2. Get the nginx-ingress-controller release name from the previous command and set it as a variable:

    ```bash
    export INGRESSRELEASE=knobby-wolf
    ```

3. Wait for the nginx-ingress-controller release to get deployed (When checking status your pod should be 'READY 1/1'):

    ```bash
    helm status $INGRESSRELEASE
    ```

4. Get the ELB IP and set it as a variable for future use:

    ```bash
    export ELBADDRESS=$(kubectl get services $INGRESSRELEASE-nginx-ingress-controller --namespace=$DESIREDNAMESPACE -o jsonpath={.status.loadBalancer.ingress[0].hostname})
    ```

### 2. Deploy the Chart:
```bash
helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator
helm install alfresco-incubator/alfresco-identity-service \
--set ingressHostName=$ELBADDRESS \
--namespace $DESIREDNAMESPACE
```

## Customizing the Realm

### Customizing the Realm During Deployment

1. You will need a realm file. A [sample realm](./alfresco-realm.json) file is provided.

2. Create a secret using your realm json file
   ```bash
   kubectl create secret generic realmsecret \
   --from-file=./realm.json \
   --namespace=$DESIREDNAMESPACE

   export secretname=realmsecret
   export secretkey=realm.json
   ```

3. Deploy the identity chart with the new settings:

    ```bash
    helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator

    helm install alfresco-incubator/alfresco-identity-service \
    --set ingressHostName=$ELBADDRESS \
    --set keycloak.secretName=$secretname \
    --set keycloak.secretKey=$secretkey \
    --namespace $DESIREDNAMESPACE
    ```

### Setting the Realm After Deployment

Once Keycloak is up and running, login to the [Management Console](http://www.keycloak.org/docs/3.4/server_admin/index.html#admin-console) to configure the required realm. 

#### Manually

1. [Add a realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) named "Alfresco"

2. [Create an OIDC client](http://www.keycloak.org/docs/3.4/server_admin/index.html#oidc-clients) named "alfresco" within the Alfresco realm

3. [Create a group](http://www.keycloak.org/docs/3.4/server_admin/index.html#groups) named "admin"

4. [Add a new user](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-new-user) with a username of "testuser", email of "test@test.com" and first and last name of "test"

#### Using the Sample Realm File

1. Go to the [Add Realm](http://www.keycloak.org/docs/3.4/server_admin/index.html#_create-realm) page and click the "Select File" button next to the **Import** label.

2. Choose the [sample realm](./alfresco-realm.json) file and click the "Create" button.

# Contributing to the Identity Service

We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

# Alfresco Identity Service

The Alfresco Identity Service provides a Single Sign On experience for the Alfresco Digital Business Platform (DBP).

The Identity Service is based on [Keycloak](http://www.keycloak.org) and provides a [sample realm](./alfresco-realm.json) file for use with the DBP.

## Prerequisites

The Alfresco Identity Service deployment requires:

| Component        | Recommended version |
| ------------- |:-------------:|
| Docker     | 17.0.9.1 |
| Kubernetes | 1.8.0    |
| Helm       | 2.8.2    |
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

This will create a ELB when using AWS and will set a dummy certificate on it.

```bash
helm repo update

cat <<EOF > ingressvalues.yaml
controller:
  config:
    ssl-redirect: "false"
  scope:
    enabled: true
EOF

helm install stable/nginx-ingress --version=0.14.0 -f ingressvalues.yaml \
  --namespace $DESIREDNAMESPACE
```

### Optional

If you want your own certificate set here you should create a secret from your cert files:

```bash
kubectl create secret tls certsecret --key /tmp/tls.key --cert /tmp/tls.crt \
  --namespace $DESIREDNAMESPACE

#Then deploy the ingress with following settings

cat <<EOF > ingressvalues.yaml
controller:
  config:
    ssl-redirect: "false"
  scope:
    enabled: true
  publishService:
    enabled: true
  extraArgs:
    default-ssl-certificate: $DESIREDNAMESPACE/certsecret
EOF

helm install stable/nginx-ingress --version=0.14.0 -f ingressvalues.yaml \
  --namespace $DESIREDNAMESPACE
```

If you

* created the cluster in AWS using [kops](https://github.com/kubernetes/kops/)
* have a matching SSL/TLS certificate stored in [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)
* are using a zone in [Amazon Route 53](https://aws.amazon.com/route53/)

Kubernetes' [External DNS](https://github.com/kubernetes-incubator/external-dns)
can autogenerate a DNS entry for you (a CNAME of the generated ELB) and apply
the SSL/TLS certificate to the ELB.

_Note: AWS Certificate Manager ARNs are of the form `arn:aws:acm:REGION:ACCOUNT:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`._

Set `DOMAIN` to the DNS Zone you used when [creating the cluster](https://github.com/kubernetes/kops/blob/master/docs/aws.md#scenario-1b-a-subdomain-under-a-domain-purchasedhosted-via-aws).

```bash
ELB_CNAME="${DESIREDNAMESPACE}.${DOMAIN}"
ELB_CERTIFICATE_ARN=$(aws acm list-certificates | \
  jq '.CertificateSummaryList[] | select (.DomainName == "'${DOMAIN}'") | .CertificateArn')

cat <<EOF > ingressvalues.yaml
controller:
  config:
    ssl-redirect: "false"
  scope:
    enabled: true
  publishService:
    enabled: true
  service:
    targetPorts:
      http: http
      https: http
    annotations:
      external-dns.alpha.kubernetes.io/hostname: ${ELB_CNAME}
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '3600'
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${ELB_CERTIFICATE_ARN}
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
EOF

helm install stable/nginx-ingress --version=0.14.0 -f ingressvalues.yaml \
  --namespace $DESIREDNAMESPACE

```

<!-- markdownlint-disable MD029 -->
2. Get the nginx-ingress-controller release name from the previous command and set it as a varible:
<!-- markdownlint-disable MD029 -->

```bash
export INGRESSRELEASE=knobby-wolf
```

<!-- markdownlint-disable MD029 -->
3. Wait for the nginx-ingress-controller release to get deployed (When checking status your pod should be READY 1/1):
<!-- markdownlint-enable MD029 -->

```bash
helm status $INGRESSRELEASE
```

<!-- markdownlint-disable MD029 -->
4. Get the nginx-ingress-controller port for the infrastructure (NOTE! ONLY FOR MINIKUBE):
<!-- markdownlint-enable MD029 -->

```bash
export INFRAPORT=$(kubectl get service $INGRESSRELEASE-nginx-ingress-controller --namespace $DESIREDNAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
```

<!-- markdownlint-disable MD029 -->
5. Get Minikube or ELB IP and set it as a variable for future use:
<!-- markdownlint-disable MD029 -->

```bash
#ON MINIKUBE
export ELBADDRESS=$(minikube ip)

#ON AWS
export ELBADDRESS=$(kubectl get services $INGRESSRELEASE-nginx-ingress-controller --namespace=$DESIREDNAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### 2. Deploy the keycloak charts

```bash
helm repo add alfresco-incubator http://kubernetes-charts.alfresco.com/incubator

#ON MINIKUBE
helm install alfresco-incubator/alfresco-identity-service \
  --set ingressHostName=$ELBADDRESS \
  --namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
  --set ingressHostName=$ELBADDRESS \
  --namespace $DESIREDNAMESPACE
```

## Customizing the keycloak Realm

### On kubernetes deploy time

1. You will need a realm json, similar to `alfresco-realm.json`

1. Create a secret using your realm json file

```bash

kubectl create secret generic realmsecret \
  --from-file=./realm.json \
  --namespace=$DESIREDNAMESPACE

```

<!-- markdownlint-disable MD029 -->
3. Deploy the identity chart with the new settings:
<!-- markdownlint-enable MD029 -->

```bash

helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator

#ON MINIKUBE
helm install alfresco-incubator/alfresco-identity-service \
--set ingressHostName=$ELBADDRESS \
--namespace $DESIREDNAMESPACE

#ON AWS
helm install alfresco-incubator/alfresco-identity-service \
--set ingressHostName=$ELBADDRESS \
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

## Contributing to Identity Service

We encourage and welcome contributions to this project. For further details please check the [contributing](./CONTRIBUTING.md) file.

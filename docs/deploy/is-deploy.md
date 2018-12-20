# Alfresco Identity Service deployment

## Prerequisites
An Identity Service deployment requires the following:

* A Kubernetes cluster (Kops or EKS)
* The following components:

|Component  |Getting Started guide                                    |
|-----------|---------------------------------------------------------|
|Docker     |https://docs.docker.com/                                 |
|Helm       |https://docs.helm.sh/using_helm/#quickstart-guide        |
|Kubectl    |https://kubernetes.io/docs/tasks/tools/install-kubectl/  |

The Identity Service can also be deployed on Docker for Desktop for development and trial purposes.

## Deploying the Identity Service
The following steps detail a default deployment of the Identity Service. See [Customizing an Identity Service deployment](./is-customize.md) for additional parameters to change or update values for:

* [default client redirect URIs](./is-customize.md#client-redirect-uris)
* [realm customization](./is-customize.md#customizing-the-realm)
* [increasing resiliency using replicas](./is-customize.md#replicas)

1. You need to deploy the [Alfresco Infrastructure chart](https://github.com/Alfresco/alfresco-infrastructure-deployment#1-deploy-the-infrastructure-charts) in order to deploy the Identity Service. Use the following command to deploy it:

   **Note:** Nginx Ingress is required for the Identity Service. Active-MQ is not required so the relevant property can be set to ``false`` as it is in the following command.
   
   ```
   helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable

   helm install alfresco-stable/alfresco-infrastructure \
     --set alfresco-infrastructure.activemq.enabled=false \
     --set alfresco-infrastructure.nginx-ingress.enabled=true \
     --set alfresco-infrastructure.alfresco-identity-service.enabled=true \
     --namespace $DESIREDNAMESPACE
   ```

2. The previous command will assign a release name to your deployment (e.g. ``knobby-wolf``). Set this release name as a variable:

   ```
   export RELEASENAME=knobby-wolf
   ```

3. Check the status of your release using the following command:

	```
	helm status $RELEASENAME
	```
	
	You need to wait until the status is ``READY 1/1``.

4. Set your local or ELB IP address as a variable for future use:

	```
	export ELBADDRESS=$(kubectl get services $RELEASENAME-nginx-ingress-controller --	namespace=$DESIREDNAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
	```

5. The default realm values are as follows. You should update all administrator passwords to more complex ones after you have deployed the Identity Service.

	| Property                      | Value                    |
	| ----------------------------- | ------------------------ |
	| Admin User Username           | `admin`                  |
	| Admin User Password           | `admin`                  |
	| Admin User Email              | `admin@app.activiti.com` |
	| Alfresco Client Redirect URIs | `http://localhost*`      |

**Note:** Alfresco Process Services requires an email address as the username.


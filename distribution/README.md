# About
> Building `alfresco-identity-service` using`quay.io/alfresco/alfresco-base-java` as base image.

> Image(s) available under:
*  private `quay.io` [![Docker Repository on Quay](https://quay.io/repository/alfresco/alfresco-identity-service/status?token=9a426dcd-f3b7-4f59-997e-56ae03bc2ce7 "Docker Repository on Quay")](https://quay.io/repository/alfresco/alfresco-identity-service)  repository
* public `hub.docker.com` [![](https://images.microbadger.com/badges/image/alfresco/alfresco-identity-service.svg)](https://microbadger.com/images/alfresco/alfresco-identity-service "Get your own image badge on microbadger.com") repository



# Usage
> checkout the [Makefile](./Makefile). All commands will be executed within this folder.

* build alfresco-identity-service distribution zip and Docker image
  
  ```shell
  $ make
  ```

* build ONLY the distribution zip
  ```shell  
  $ make distribution
  ```

* build the image (if you have the distribution zip)
  ```shell  
  # this will create the image that will be stored in quay.io
  $ make private_image
  
  # this will create the image that will be stored in hub.docker.com
  $ make public_image
  ```

* start alfresco-identity-service (open http://localhost:8080/auth)

  ```shell
  $ make run 
  ```

* open a shell inside alfresco-identity-service container for debugging
  
  ```shell
  $ make sh
  ```

* kill the container
  ```shell
  $ make stop
  ```

* push the image to quay.io
  ```shell
  $ make push_private
  ```

* push the image to hub.docker.com
```shell
$ make push_public
```

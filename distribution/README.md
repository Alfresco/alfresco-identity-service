# About
> Building `alfresco-identity-service` [![Docker Repository on Quay](https://quay.io/repository/alfresco/alfresco-identity-service/status?token=9a426dcd-f3b7-4f59-997e-56ae03bc2ce7 "Docker Repository on Quay")](https://quay.io/repository/alfresco/alfresco-identity-service)  based on `quay.io/alfresco/alfresco-base-java`.

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
  $ make image
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

* push the image to quay
  ```shell
  $ make push
  ```

# Release

There are no artifacts to be distributed, therefore the release process is only required to produce snapshots in time of testing specific Keycloak + Alfresco Keycloak Theme combinations.

Once a new Keycloak + Alfresco Keycloak Theme combination has been thoroughly tested and is ready to be snapshotted for future reference, simply:

  1. Make sure everything is merged onto `master`
  
  2. Checkout the `master` branch locally:
  
     `git checkout master`
  
  3. Pull the latest changes:
  
     `git pull`
  
  4. Produce the required tag:
  
     `./tag.sh`

> **NOTE:** make sure that the expected `KEYCLOAK_VERSION` and `THEME_VERSION` are set within the [build.properties](../distribution/build.properties) file.

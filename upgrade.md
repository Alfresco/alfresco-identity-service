# Upgrading Identity Service

## Upgrading from Identity Service 1.1 to 1.2

  **_NOTE:_** The upgrade of the Alfresco Identity Management Service requires downtime. 
  This means that no user will be able to connect to any of the Digital Business Platform components while the upgrade or rollback is being done.

### General upgrade procedure

For upgrading Alfresco Identity Management Service we are mainly following the Keycloak upgrade procedure.
We will be explaining how to do it if you are using our out of the box distribution or Kubernetes deployment.
However depending on the environment you are using you should follow these high-level steps:

1. Prior to applying the upgrade, [handle any open transactions](https://www.keycloak.org/docs/4.8/server_admin/#user-session-management) and delete the data/tx-object-store/ transaction directory.

2. Back up the old installation (configuration, themes, and so on).

3. Back up the database. For detailed information on how to back up the database, see the documentation for the relational database you are using.

4. Upgrade Keycloak server.

   - Testing the upgrade in a non-production environment first, to prevent any installation issues from being exposed in production, is a best practice.

   - Be aware that after the upgrade the database will no longer be compatible with the old server

   - Ensure the upgraded server is functional before upgrading adapters in production.

5. If you need to revert the upgrade, first restore the old installation, and then restore the database from the backup copy.

Within the next sections we will go through a simple distribution and Kubernetes upgrade plus rollback.

  **_NOTE:_** In depth documentation on Keycloak upgrade can be found [here](https://www.keycloak.org/docs/7.0/upgrading/index.html#_upgrading).

### Kubernetes

#### Generic Information

To do the upgrade in Kubernetes we are taking advantage of Kubernetes jobs and Helm hooks.

These are the steps we are following for a smooth upgrade transition without any manual intervention:

1. Pre-Upgrade job is running to remove the Keycloak statefulset, thus killing of any existent user session.
2. Pre-Upgrade job is running to create an extra volume for backing up the PostgreSQL database.
3. Pre-Upgrade job to do the backup of the database.
4. Pre-Upgrade job to delete the database deployment so that it does not clash with the new PostgreSQL deployment.
5. Post-Upgrade job to scale the new Keycloak to 0 replicas so we can restore the database initially.
6. Post-Upgrade job to restore the database data.
7. Post-Upgrade job to re-scale Keycloak back to 1 replica so that it can start using the new data.

This process leaves us with an additional volume containing the database backup.
That volume will be used in the case a rollback is done but will be deleted when the entire release is being deleted.

For the rollback process we are using the following jobs:

1. Pre-rollback job to kill off the current statefulsets.
2. Post-rollback job to scale Keycloak to 0 replicas.
3. Post-rollback job to restore the database from backup.
4. Post-rollback job to scale Keycloak to 1 replica.

#### How to upgrade

  **_NOTE:_** This upgrade works only from 1.1 to 1.2 version of the Alfresco Identity Management Service .

1. Identify your infrastructure chart deployment and save it in a variable.

```bash
export RELEASENAME=knobby-wolf
```

2. Run the helm upgrade command using the new version of the infrastructure chart that contains Alfresco Identity Management Service 1.2.
If you however have the Digital Business Platform Helm Chart installed you will need to upgrade to a newer DBP chart which containes Alfresco Identity Management Service 1.2.

```bash
helm upgrade $RELEASENAME alfresco-incubator/alfresco-infrastructure --version 5.2.0
```

3. A series of jobs will be running to do the upgrade after which you will be able to access the AIMS server at the same location. The AIMS service should be back up in a few minutes.

#### How to Rollback

1. If for any reason the upgrade to 1.2 failed or you just want to rollback to 1.1 issue the following command:

```bash
helm rollback --force --recreate-pods --cleanup-on-fail $RELEASENAME 1
```

The AIMS service will be back to it's original state in a few minutes.

### ZIP Distribution

#### Upgrade example for Identity Service with PostgreSQL database

1. Backup the old installation by performing:

```bash
pg_dump --clean --no-owner --no-acl -h ${POSTGRES_HOST} -p ${POSTGRES_PORT}  -U ${POSTGRES_USER} ${POSTGRES_DATABASE} | grep -v -E '(DROP\ SCHEMA\ public|CREATE\ SCHEMA\ public|COMMENT\ ON\ SCHEMA\ public|DROP\ EXTENSION\ plpgsql|CREATE\ EXTENSION\ IF\ NOT\ EXISTS\ plpgsql|COMMENT\ ON\ EXTENSION\ plpgsql)' > /backup/backup.sql
```
	
2. Remove old data and stop the PostgreSQL instance.

3. Stop the Identity Service 1.1 server.

4. Open Identity Service 1.2 distribution zip and configure accordingly to the database that will be used (for this example PostgreSQL).
   For detailed information on how to set up the desired database this visit the official documentation of Keycloak [here](https://www.keycloak.org/docs/7.0/server_installation/#_database).
   
5. Start the database and restore data by executing the following command:

```bash
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DATABASE} -U ${POSTGRES_USER} -f /backup/backup.sql
``` 

6. Start Identity Service 1.2 as described [here](https://github.com/Alfresco/alfresco-identity-service/blob/master/README.md#installing-and-booting).

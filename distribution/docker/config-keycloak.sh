#!/bin/bash -e

#####################
# Create DB modules #
#####################

mkdir -p $JBOSS_HOME/modules/system/layers/base/com/mysql/jdbc/main
cd $JBOSS_HOME/modules/system/layers/base/com/mysql/jdbc/main
curl -O https://repo1.maven.org/maven2/mysql/mysql-connector-java/$JDBC_MYSQL_VERSION/mysql-connector-java-$JDBC_MYSQL_VERSION.jar
cp /opt/jboss/tools/databases/mysql/module.xml .

mkdir -p $JBOSS_HOME/modules/system/layers/base/org/postgresql/jdbc/main
cd $JBOSS_HOME/modules/system/layers/base/org/postgresql/jdbc/main
curl -L https://repo1.maven.org/maven2/org/postgresql/postgresql/$JDBC_POSTGRES_VERSION/postgresql-$JDBC_POSTGRES_VERSION.jar > postgres-jdbc.jar
cp /opt/jboss/tools/databases/postgres/module.xml .

mkdir -p $JBOSS_HOME/modules/system/layers/base/org/mariadb/jdbc/main
cd $JBOSS_HOME/modules/system/layers/base/org/mariadb/jdbc/main
curl -L https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/$JDBC_MARIADB_VERSION/mariadb-java-client-$JDBC_MARIADB_VERSION.jar > mariadb-jdbc.jar
cp /opt/jboss/tools/databases/mariadb/module.xml .

mkdir -p $JBOSS_HOME/modules/system/layers/base/com/oracle/jdbc/main
cd $JBOSS_HOME/modules/system/layers/base/com/oracle/jdbc/main
cp /opt/jboss/tools/databases/oracle/module.xml .

mkdir -p $JBOSS_HOME/modules/system/layers/keycloak/com/microsoft/sqlserver/jdbc/main
cd $JBOSS_HOME/modules/system/layers/keycloak/com/microsoft/sqlserver/jdbc/main
curl -L https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/$JDBC_MSSQL_VERSION/mssql-jdbc-$JDBC_MSSQL_VERSION.jar > mssql-jdbc.jar
cp /opt/jboss/tools/databases/mssql/module.xml .

######################
# Configure Keycloak #
######################

cd $JBOSS_HOME

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/standalone-configuration.cli
rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/standalone-ha-configuration.cli
rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history

###################
# Set permissions #
###################

echo "alfresco:x:1000:1000:Alfresco user:/opt/jboss:/sbin/nologin" >> /etc/passwd
chown -R alfresco:0 /opt/jboss
chmod -R g+rw /opt/jboss
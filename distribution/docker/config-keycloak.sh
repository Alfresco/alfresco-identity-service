#!/bin/bash -e

######################
# Configure Keycloak #
######################

cd $AIMS_HOME

bin/jboss-cli.sh --file=$ALFRESCO_HOME/scripts/cli/standalone-configuration.cli
rm -rf $AIMS_HOME/standalone/configuration/standalone_xml_history

bin/jboss-cli.sh --file=$ALFRESCO_HOME/scripts/cli/standalone-ha-configuration.cli
rm -rf $AIMS_HOME/standalone/configuration/standalone_xml_history

###################
# Set permissions #
###################

echo "alfresco:x:1000:1000:Alfresco user:$ALFRESCO_HOME:/sbin/nologin" >> /etc/passwd
chown -R alfresco:0 $ALFRESCO_HOME
chmod -R g+rw $ALFRESCO_HOME
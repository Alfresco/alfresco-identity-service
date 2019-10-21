#!/bin/bash -e

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
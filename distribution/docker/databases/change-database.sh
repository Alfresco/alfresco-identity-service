#!/bin/bash -e

DB_VENDOR=$1

cd /opt/jboss/keycloak

$JBOSS_HOME/bin/jboss-cli.sh --file=/opt/jboss/tools/cli/databases/$DB_VENDOR/standalone-configuration.cli
rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history

$JBOSS_HOME/bin/jboss-cli.sh --file=/opt/jboss/tools/cli/databases/$DB_VENDOR/standalone-ha-configuration.cli
rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history/current/*

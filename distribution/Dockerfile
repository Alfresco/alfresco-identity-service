FROM quay.io/alfresco/alfresco-base-java:8
LABEL version="1.0"
LABEL maintainer="Platform Services Team"

ARG IDENTITY_VERSION=1.2

ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 5.1.46
ENV JDBC_MARIADB_VERSION 2.2.3
ENV JDBC_MSSQL_VERSION 7.4.1.jre8

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV LANG en_US.UTF-8

ENV IDENTITY_SERVICE_NAME alfresco-identity-service-$IDENTITY_VERSION
ENV JBOSS_HOME /opt/jboss/alfresco-identity-service
WORKDIR /opt/jboss

USER root

RUN yum update -y && yum install -y jq openssl which && yum clean all

COPY $IDENTITY_SERVICE_NAME $JBOSS_HOME

COPY ./docker/ tools
RUN chmod +x tools/config-keycloak.sh && \
    tools/config-keycloak.sh

USER 1000

EXPOSE 8080

ENTRYPOINT [ "tools/docker-entrypoint.sh" ]
CMD ["-b", "0.0.0.0"]

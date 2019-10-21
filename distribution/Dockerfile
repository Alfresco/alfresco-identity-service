FROM quay.io/alfresco/alfresco-base-java:8
LABEL version="1.0"
LABEL maintainer="Platform Services Team"

ARG IDENTITY_VERSION=1.2-Cristina
ENV KEYCLOAK_USER=admin
ENV KEYCLOAK_PASSWORD=admin
ENV DB_VENDOR=H2
ENV LANG en_US.UTF-8

ENV IDENTITY_SERVICE_NAME alfresco-identity-service-$IDENTITY_VERSION
ENV ALFRESCO_HOME /opt/alfresco
ENV AIMS_HOME $ALFRESCO_HOME/alfresco-identity-service
WORKDIR $ALFRESCO_HOME

USER root

RUN yum update -y && yum install -y jq openssl which && yum clean all

COPY $IDENTITY_SERVICE_NAME $AIMS_HOME

COPY ./docker/ scripts
RUN chmod +x scripts/config-keycloak.sh && \
    scripts/config-keycloak.sh

USER 1000

EXPOSE 8080

ENTRYPOINT [ "scripts/docker-entrypoint.sh" ]
CMD ["-b", "0.0.0.0"]

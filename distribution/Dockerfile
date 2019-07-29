FROM quay.io/alfresco/alfresco-base-java:8
LABEL version="1.0"
LABEL maintainer="Platform Services Team"

ARG IDENTITY_VERSION=1.2
# ENV KEYCLOAK_USER=admin
# ENV KEYCLOAK_PASSWORD=admin
ENV DB_VENDOR=H2
ENV LANG en_US.UTF-8

ENV IDENTITY_SERVICE_NAME alfresco-identity-service-$IDENTITY_VERSION.zip
ENV JBOSS_HOME /alfresco-identity-service-$IDENTITY_VERSION

COPY $IDENTITY_SERVICE_NAME .
RUN yum install -y unzip && yum clean all && \
    unzip -oq $IDENTITY_SERVICE_NAME && \
    rm -rf $IDENTITY_SERVICE_NAME

COPY ./docker/ /scripts/

EXPOSE 8080

ENTRYPOINT [ "/scripts/docker-entrypoint.sh" ]
CMD ["-b", "0.0.0.0"]

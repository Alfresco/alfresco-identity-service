FROM quay.io/alfresco/alfresco-base-java:8
LABEL version="1.0"
LABEL maintainer="Platform Services Team"

ARG IDENTITY_VERSION=1.2
ENV DB_VENDOR=H2
ENV LANG en_US.UTF-8

ENV PROXY_ADDRESS_FORWARDING true

ENV IDENTITY_SERVICE_NAME alfresco-identity-service-$IDENTITY_VERSION.zip
ENV JBOSS_HOME /alfresco-identity-service-$IDENTITY_VERSION

COPY $IDENTITY_SERVICE_NAME .
RUN yum install -y unzip && yum clean all && \
    unzip -oq $IDENTITY_SERVICE_NAME && \
    rm -rf $IDENTITY_SERVICE_NAME && \
    chmod 777 -R $JBOSS_HOME

USER root

RUN yum update -y && yum install -y epel-release git && yum install -y jq openssl which && yum clean all

USER 1000

COPY ./docker/ /opt/jboss/tools/

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]
CMD ["-b", "0.0.0.0"]

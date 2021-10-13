#
# Stage: first / main
#
FROM centos:7 as main

MAINTAINER Manuel Holtgrewe <manuel.holtgrewe@bih-charite.de>
LABEL org.opencontainers.image.source https://github.com/bihealth/irods-docker

# Environment variables for container runtime
# TODO: Setup for resc-only mode
ENV IRODS_PKG_VERSION=4.2.8-1 \
    IRODS_HOST_NAME=localhost \
    IRODS_SERVICE_ACCOUNT_USER=irods \
    IRODS_SERVICE_ACCOUNT_GROUP=irods \
    IRODS_ADMIN_USER=rods \
    IRODS_ADMIN_PASS=rods \
    IRODS_ZONE_NAME=demoZone \
    IRODS_ZONE_KEY=TEMPORARY_zone_key \
    IRODS_ZONE_PORT=1247 \
    IRODS_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key \
    IRODS_ODBC_DRIVER="PostgreSQL" \
    IRODS_ICAT_DBSERVER=postgres \
    IRODS_ICAT_DBPORT=5432 \
    IRODS_ICAT_DBNAME=ICAT \
    IRODS_ICAT_DBUSER=irods \
    IRODS_ICAT_DBPASS=irods \
    IRODS_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key \
    IRODS_CONTROL_PLANE_PORT=1248 \
    IRODS_DATA_PORT_RANGE_START=20000 \
    IRODS_DATA_PORT_RANGE_END=20199 \
    IRODS_SSL_VERIFY_SERVER=none \
    IRODS_PASSWORD_SALT=tempsalt \
    IRODS_ROLE=provider \
    IRODS_SSL_CA_CERT_PATH= \
    IRODS_AUTHENTICATION_SCHEME=native \
    IRODS_CLIENT_SERVER_NEGOTIATION=off \
    IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE \
    IRODS_RESOURCE_DIRECTORY=/data/Vault

# Add the wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /usr/local/bin/wait
RUN chmod +x /usr/local/bin/wait

# Install repositories and install latest updates
RUN yum install -y epel-release && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    curl https://packages.irods.org/renci-irods.yum.repo \
        > /etc/yum.repos.d/renci-irods.yum.repo && \
    yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum clean all && \
    yum upgrade -y

# Install dependency packages
RUN yum install -y \
        postgresql11 \
        sudo \
        nc

# Install j2cli for templating
RUN yum -y install python-pip python-jinja2 python-yaml
RUN pip install j2cli

# Install iRODS
RUN yum -y install \
    irods-server-${IRODS_PKG_VERSION}.x86_64.rpm \
    irods-database-plugin-postgres \
    irods-devel \
  && useradd -d /var/lib/irods ${IRODS_SERVICE_ACCOUNT_USER} \
  && yum clean all \
  && rm -rf /var/cache/yum/* \
  && rm -rf /tmp/*

# Install iRODS python rule-engine plugin
RUN yum -y install irods-rule-engine-plugin-python
COPY files/irods_python-re_installer.py /
RUN chmod +x /irods_python-re_installer.py

# Copy scripts
COPY docker-entrypoint.sh files/irods_login.sh \
     templates/core.py.template templates/unattended_config.json.j2 files/j2-filters.py /
RUN chmod +x /docker-entrypoint.sh /irods_login.sh

# Create iRODS vault dir
RUN mkdir -p $IRODS_RESOURCE_DIRECTORY
RUN chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER $IRODS_RESOURCE_DIRECTORY

# Data volumes
VOLUME "/etc/irods" "/var/lib/irods/iRODS/server/log"

# Network ports
EXPOSE 4321 $IRODS_ZONE_PORT $IRODS_CONTROL_PLANE_PORT $IRODS_DATA_PORT_RANGE_START-$IRODS_DATA_PORT_RANGE_END

# Entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["icat-enabled"]

#
# Stage: add SSSD support
#

FROM main AS sssd

RUN yum install -y \
        sssd \
        sssd-ldap \
        sssd-tools \
        strace \
  && yum clean all \
  && rm -rf /var/cache/yum/* \
  && rm -rf /tmp/*

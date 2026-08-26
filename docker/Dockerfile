# check=skip=SecretsUsedInArgOrEnv

#
# Stage: first / main
#
FROM ubuntu:24.04 AS main

LABEL org.opencontainers.image.authors="Manuel Holtgrewe <manuel.holtgrewe@bih-charite.de>, Mikko Nieminen <mikko.nieminen@bih-charite.de>, Oliver Stolpe <oliver.stolpe@charite.de>, Federico Marotta <federico.marotta@bih-charite.de>"
LABEL org.opencontainers.image.source=https://github.com/bihealth/irods-docker

ARG DEBIAN_FRONTEND="noninteractive"
ARG UBUNTU_VERSION_NAME="noble"
ARG IRODS_PKG_VERSION="4.3.5"
ARG IRODS_PYTHON_RULE_ENGINE_VERSION="4.3.5.0"
ARG IRODS_RESOURCE_PLUGIN_S3_VERSION="4.3.5.0"
ARG IRODS_PKG_SUFFIX="-0~${UBUNTU_VERSION_NAME}"
ARG IRODS_PLUGIN_SUFFIX="-0+${IRODS_PKG_VERSION}~${UBUNTU_VERSION_NAME}"

# Environment variables for container runtime
ENV IRODS_PKG_VERSION=$IRODS_PKG_VERSION \
    IRODS_ROLE=provider \
    IRODS_HOST_NAME=localhost \
    IRODS_SERVICE_ACCOUNT_USER=irods \
    IRODS_SERVICE_ACCOUNT_GROUP=irods \
    IRODS_SERVICE_ACCOUNT_UID=1000 \
    IRODS_SERVICE_ACCOUNT_GID=1000 \
    IRODS_ADMIN_USER=rods \
    IRODS_ADMIN_PASS=rods \
    IRODS_ZONE_NAME=demoZone \
    IRODS_ZONE_PORT=1247 \
    IRODS_ZONE_KEY=TEMPORARY_zone_key \
    IRODS_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key \
    IRODS_CONTROL_PLANE_PORT=1248 \
    IRODS_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key \
    IRODS_DATA_PORT_RANGE_START=20000 \
    IRODS_DATA_PORT_RANGE_END=20199 \
    IRODS_SSL_CERTIFICATE_CHAIN_FILE=/etc/irods/server.crt \
    IRODS_SSL_CERTIFICATE_KEY_FILE=/etc/irods/server.key \
    IRODS_SSL_DH_PARAMS_FILE=/etc/irods/dhparams.pem \
    IRODS_SSL_VERIFY_SERVER=none \
    IRODS_PASSWORD_SALT=tempsalt \
    IRODS_SSL_CA_CERT_PATH= \
    IRODS_CLIENT_SERVER_NEGOTIATION=request_server_negotiation \
    IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE \
    IRODS_DEFAULT_RESOURCE_NAME=demoResc \
    IRODS_RESOURCE_DIRECTORY=/data/Vault \
    IRODS_DEFAULT_HASH_SCHEME="SHA256" \
    IRODS_ODBC_DRIVER="PostgreSQL Unicode" \
    IRODS_ICAT_DBSERVER=postgres \
    IRODS_ICAT_DBPORT=5432 \
    IRODS_ICAT_DBNAME=ICAT \
    IRODS_ICAT_DBUSER=irods \
    IRODS_ICAT_DBPASS=irods \
    IRODS_LOG_LEVEL=info \
    IRODS_CATALOG_PROVIDER_HOST= \
    IRODS_SSSD_AUTH=0 \
    IRODS_SODAR_AUTH=0 \
    IRODS_SODAR_API_HOST=https://sodar-web \
    IRODS_PASSWORD_MIN_TIME=1209600 \
    PURGE_SYSTEMD_TIMESYNCD=0

# Add the wait script to the image
ADD --chmod=+x https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.1/wait /usr/local/bin/wait

# Remove default ubuntu user
# https://bugs.launchpad.net/cloud-images/+bug/2005129
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

# Install general dependencies
RUN apt update && \
    apt install -y \
        wget \
        gpg \
        jq \
        j2cli \
        vim \
        netcat-openbsd \
        python3-requests

# Install database dependencies
RUN apt install -y \
        postgresql-client \
        unixodbc-dev \
        odbc-postgresql \
        python3-pyodbc

# Install logging dependencies
RUN apt install -y \
        rsyslog \
        logrotate

# Install iRODS and plugins
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | \
    gpg \
        --no-options \
        --no-default-keyring \
        --no-auto-check-trustdb \
        --homedir /dev/null \
        --no-keyring \
        --import-options import-export \
        --output /etc/apt/keyrings/renci-irods-archive-keyring.pgp \
        --import
RUN echo "deb [signed-by=/etc/apt/keyrings/renci-irods-archive-keyring.pgp arch=amd64] https://packages.irods.org/apt/ ${UBUNTU_VERSION_NAME} main" | \
    tee /etc/apt/sources.list.d/renci-irods.list
RUN apt update && \
    apt install -y \
        irods-server=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
        irods-runtime=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
        irods-icommands=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
        irods-dev=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
        irods-database-plugin-postgres=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
        irods-rule-engine-plugin-python=${IRODS_PYTHON_RULE_ENGINE_VERSION}${IRODS_PLUGIN_SUFFIX} \
        irods-resource-plugin-s3=${IRODS_RESOURCE_PLUGIN_S3_VERSION}${IRODS_PLUGIN_SUFFIX}

# Add configuration files and templates
COPY docker-entrypoint.sh /
COPY templates/ /
COPY files/rsyslog.conf /etc/rsyslog.conf
COPY files/irods_syslog.conf /etc/rsyslog.d/00-irods.conf
COPY files/irods.logrotate /etc/logrotate.d/irods
COPY files/sodar_auth_pam.py /var/lib/irods/sodar_auth_pam.py

# Data volumes
VOLUME "/etc/irods"

# Entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["irods-start"]

#
# Stage: add SSSD support
#

FROM main AS sssd

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update
RUN apt-get install -y sssd sssd-ldap sssd-tools strace

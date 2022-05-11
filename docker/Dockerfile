#
# Stage: first / main
#
FROM ubuntu:18.04 as main

LABEL org.opencontainers.image.authors="Manuel Holtgrewe <manuel.holtgrewe@bih-charite.de>, Mikko Nieminen <mikko.nieminen@bih-charite.de>"
LABEL org.opencontainers.image.source https://github.com/bihealth/irods-docker

ARG DEBIAN_FRONTEND=noninteractive

# Environment variables for container runtime
ENV IRODS_PKG_VERSION=4.2.11-1 \
    IRODS_ROLE=provider \
    IRODS_HOST_NAME=localhost \
    IRODS_SERVICE_ACCOUNT_USER=irods \
    IRODS_SERVICE_ACCOUNT_GROUP=irods \
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
    IRODS_AUTHENTICATION_SCHEME=native \
    IRODS_CLIENT_SERVER_NEGOTIATION=off \
    IRODS_CLIENT_SERVER_POLICY=CS_NEG_REFUSE \
    IRODS_RESOURCE_DIRECTORY=/data/Vault \
    IRODS_DEFAULT_HASH_SCHEME="SHA256" \
    IRODS_ODBC_DRIVER="PostgreSQL" \
    IRODS_ICAT_DBSERVER=postgres \
    IRODS_ICAT_DBPORT=5432 \
    IRODS_ICAT_DBNAME=ICAT \
    IRODS_ICAT_DBUSER=irods \
    IRODS_ICAT_DBPASS=irods \
    IRODS_CATALOG_PROVIDER_HOST= \
    IRODS_SSSD_AUTH=0 \
    IRODS_SODAR_AUTH=0 \
    IRODS_SODAR_AUTH_VERIFY=0 \
    IRODS_SODAR_API_HOST=https://sodar-web

# Add the wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /usr/local/bin/wait
RUN chmod +x /usr/local/bin/wait

# Install general dependencies
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y python python-pip python-dev sudo vim wget netcat lsb-release

# Install database dependencies
RUN apt-get install -y unixodbc unixodbc-dev odbc-postgresql

# Install iRODS
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
  && echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/renci-irods.list \
  && apt-get update
RUN apt-get install -y irods-server=${IRODS_PKG_VERSION}~bionic \
    irods-database-plugin-postgres=${IRODS_PKG_VERSION}~bionic \
    irods-dev=${IRODS_PKG_VERSION}~bionic \
    irods-rule-engine-plugin-python
RUN useradd -d /var/lib/irods ${IRODS_SERVICE_ACCOUNT_USER}

# Copy rule-engine installer
COPY files/irods_python-re_installer.py /
RUN chmod +x /irods_python-re_installer.py

# Install j2cli for templating
RUN apt-get install -y python-jinja2 python-yaml
RUN pip install j2cli

# Install Python PAM support
RUN apt-get install libpam-python pamtester

# Copy scripts and templates
COPY docker-entrypoint.sh files/irods_login.sh \
     templates/core.py.template templates/unattended_config.json.j2 \
     templates/irods.pam.j2 files/j2-filters.py /
RUN chmod +x /docker-entrypoint.sh /irods_login.sh

# Copy PAM auth
COPY files/pam_sodar.py /usr/local/lib/pam-sodar/

# Create iRODS vault dir
RUN mkdir -p $IRODS_RESOURCE_DIRECTORY
RUN chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER $IRODS_RESOURCE_DIRECTORY

# Data volumes
VOLUME "/etc/irods" "/var/lib/irods/iRODS/server/log"

# Network ports
EXPOSE 4321 $IRODS_ZONE_PORT $IRODS_CONTROL_PLANE_PORT $IRODS_DATA_PORT_RANGE_START-$IRODS_DATA_PORT_RANGE_END

# Entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["irods-start"]

#
# Stage: add SSSD support
#

FROM main AS sssd

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y sssd sssd-ldap sssd-tools strace

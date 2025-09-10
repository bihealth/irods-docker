#
# Stage: first / main
#
FROM ubuntu:20.04 AS main

LABEL org.opencontainers.image.authors="Manuel Holtgrewe <manuel.holtgrewe@bih-charite.de>, Mikko Nieminen <mikko.nieminen@bih-charite.de>"
LABEL org.opencontainers.image.source https://github.com/bihealth/irods-docker

ARG DEBIAN_FRONTEND=noninteractive
ARG IRODS_PKG_VERSION="4.3.4"
ARG IRODS_PKG_SUFFIX="-0~focal"
ARG IRODS_PYTHON_RULE_ENGINE_VERSION="4.3.4.0-0+4.3.4"

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
    IRODS_CATALOG_PROVIDER_HOST= \
    IRODS_SSSD_AUTH=0 \
    IRODS_SODAR_AUTH=0 \
    IRODS_SODAR_API_HOST=https://sodar-web \
    IRODS_PASSWORD_MIN_TIME=1209600

# Add the wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /usr/local/bin/wait
RUN chmod +x /usr/local/bin/wait

# Install general dependencies
RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y python3 python3-dev python3-distro python3-pip sudo vim wget netcat rsyslog
# lsb-release g++ gnupg2

# Install database dependencies
RUN apt-get install -y unixodbc unixodbc-dev odbc-postgresql

# Install iRODS Python dependencies
RUN pip3 install pyodbc

# Install iRODS
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add - \
  && echo "deb [arch=amd64] https://packages.irods.org/apt/ focal main" | sudo tee /etc/apt/sources.list.d/renci-irods.list \
  && apt-get update
RUN apt-get install -y irods-runtime=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
    irods-server=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
    irods-database-plugin-postgres=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
    irods-icommands=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
    irods-dev=${IRODS_PKG_VERSION}${IRODS_PKG_SUFFIX} \
    irods-rule-engine-plugin-python=${IRODS_PYTHON_RULE_ENGINE_VERSION}~focal

# Install j2cli for templating
RUN apt-get install -y python3-jinja2 python3-yaml
RUN pip3 install j2cli

# Install Python PAM support
RUN apt-get update
RUN apt-get install -y libpam-python pamtester
# NOTE: Python2 needed for custom PAM module
RUN apt-get install -y python python-dev
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python2 get-pip.py
RUN pip install requests

# Copy scripts and templates
COPY docker-entrypoint.sh \
     templates/core.py.j2 templates/unattended_config.json.j2 \
     templates/irods.pam.j2 files/j2-filters.py templates/pam_sodar.py.j2 /
RUN chmod +x /docker-entrypoint.sh

# Set up logging
COPY files/irods_syslog.conf /etc/rsyslog.d/00-irods.conf
COPY files/irods.logrotate /etc/logrotate.d/irods
RUN chmod 0644 /etc/logrotate.d/irods
RUN mkdir -p /var/log/irods

# Data volumes
VOLUME "/etc/irods"

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
RUN apt-get update
RUN apt-get install -y sssd sssd-ldap sssd-tools strace

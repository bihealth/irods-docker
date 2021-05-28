#
# Stage: first / main
#
FROM centos:7 as main

MAINTAINER Manuel Holtgrewe <manuel.holtgrewe@bih-charite.de>
LABEL org.opencontainers.image.source https://github.com/bihealth/irods-docker

ENV IRODS_PKG_VERSION=4.2.8-1

# Add the wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /usr/local/bin/wait
RUN chmod +x /usr/local/bin/wait

# Install repositories and install latest updates.
RUN yum install -y epel-release && \
    rpm --import https://packages.irods.org/irods-signing-key.asc && \
    curl https://packages.irods.org/renci-irods.yum.repo \
        > /etc/yum.repos.d/renci-irods.yum.repo && \
    yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum clean all && \
    yum upgrade -y

# Install dependency packages
RUN yum install -y \
        postgresql12 \
        sudo

# Install iRODS
RUN yum -y install \
    irods-server-${IRODS_PKG_VERSION}.x86_64.rpm \
    irods-database-plugin-postgres \
    irods-devel \
  && useradd -d /var/lib/irods irods \
  && yum clean all \
  && rm -rf /var/cache/yum/* \
  && rm -rf /tmp/*

## installing irods python rule-engine plugin
RUN yum -y install irods-rule-engine-plugin-python
COPY irods_python-re_installer.py /
RUN chmod +x /irods_python-re_installer.py

## environment variables for container runtime
ENV IRODS_ADMIN_USER=rods
ENV IRODS_ADMIN_PASS=rods
ENV IRODS_ZONE_NAME=demoZone
ENV IRODS_ZONE_KEY=TEMPORARY_zone_key
ENV IRODS_ZONE_PORT=1247
ENV IRODS_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key
ENV IRODS_ICAT_DBSERVER=postgres
ENV IRODS_ICAT_DBPORT=5432
ENV IRODS_ICAT_DBNAME=ICAT
ENV IRODS_ICAT_DBUSER=rods
ENV IRODS_ICAT_DBPASS=rods
ENV IRODS_CONTROLPLANE_PORT=1248
ENV IRODS_CONTROLPLANE_KEY=TEMPORARY__32byte_ctrl_plane_key
ENV IRODS_DATA_PORT_RANGE_BEG=20000
ENV IRODS_DATA_PORT_RANGE_END=20199

## copy scripts
COPY genresp.sh docker-entrypoint.sh irods_login.sh core.py.template /
RUN chmod +x /genresp.sh /docker-entrypoint.sh /irods_login.sh

## data volumes
VOLUME "/etc/irods" "/var/lib/irods/iRODS/server/log" "/var/lib/irods/Vault"

## network ports
EXPOSE 4321 $IRODS_ZONE_PORT $IRODS_CONTROLPLANE_PORT $IRODS_DATA_PORT_RANGE_BEG-$IRODS_DATA_PORT_RANGE_END

## entrypoint
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

#!/bin/bash

NO_WAIT=${NO_WAIT-0}
export PGPASSWORD=$IRODS_ICAT_DBPASS
set -euo pipefail

if [[ "$1" == "irods-start" ]]; then

    # Set up service user and permissions
    groupadd -f -g $IRODS_SERVICE_ACCOUNT_GID $IRODS_SERVICE_ACCOUNT_GROUP
    useradd -d /var/lib/irods -s /bin/bash -u $IRODS_SERVICE_ACCOUNT_UID -g $IRODS_SERVICE_ACCOUNT_GID $IRODS_SERVICE_ACCOUNT_USER || true
    chmod a+x /var/lib/irods/irodsctl
    chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER /etc/irods

    # Create iRODS resource dir
    mkdir -p $IRODS_RESOURCE_DIRECTORY
    chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER $IRODS_RESOURCE_DIRECTORY

    # Set up logging
    sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
    chown syslog:adm /var/log/irods
    touch /var/log/irods/irods.log
    chown syslog:adm /var/log/irods/irods.log
    rm -f /var/run/rsyslogd.pid
    /etc/init.d/rsyslog start

    echo "iRODS server role: $IRODS_ROLE"

    if [[ "$IRODS_ROLE" == "provider" ]] && [[ "$NO_WAIT" -ne 1 ]]; then
        echo "Waiting for postgres.."
        export WAIT_HOSTS=${WAIT_HOSTS-${IRODS_ICAT_DBSERVER}:${IRODS_ICAT_DBPORT}}
        /usr/local/bin/wait
        PSQL="pg_isready -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT"
        fi
    fi

    if [ -f /etc/irods/.provisioned ]; then

        echo "Skipping iRODS provisioning.."

        if [ ! -f /var/lib/irods/.irods/irods_environment.json ]; then
            mkdir -p /var/lib/irods/.irods
            cp /etc/irods/irods_environment.json /var/lib/irods/.irods/irods_environment.json
        fi

        if [ ! -f /var/lib/irods/.odbc.ini ]; then
            cp /etc/irods/.odbc.ini /var/lib/irods/.odbc.ini
        fi

        if [ -f /etc/irods/version.json ]; then
            cp -f /etc/irods/version.json /var/lib/irods/version.json
        fi

    else

        echo "Provisioning iRODS.."

        if [[ "$IRODS_ROLE" == "provider" ]]; then

            if [ "$( psql -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT -U $IRODS_ICAT_DBUSER \
                -XtAc "SELECT 1 FROM pg_database WHERE datname='$IRODS_ICAT_DBNAME'" )" = '1' ]
            then
                echo "iCAT database already exists, skipping creation"
            else
                echo "Create iCAT database"
                createdb -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT -U $IRODS_ICAT_DBUSER -W $IRODS_ICAT_DBNAME
            fi

        fi

        echo "Set up unattended configuration file"
        j2 -o /unattended_config.json --undefined --filters=j2-filters.py unattended_config.json.j2

        echo "Set up rule file for the Python rule engine"
        j2 -o /core.py --undefined --filters=j2-filters.py core.py.j2
        cp -f /core.py /etc/irods/core.py

        echo "Perform iRODS setup"
        python3 /var/lib/irods/scripts/setup_irods.py --json_configuration_file=/unattended_config.json

        cp /var/lib/irods/.irods/irods_environment.json /etc/irods/irods_environment.json
        cp /var/lib/irods/.odbc.ini /etc/irods/.odbc.ini
        cp -f /var/lib/irods/version.json /etc/irods/version.json

        touch /etc/irods/.provisioned

    fi

    if [[ "$IRODS_ROLE" == "provider" ]]; then

        echo "Set up custom PAM module"
        mkdir -p /usr/local/lib/pam-sodar
        j2 -o /usr/local/lib/pam-sodar/pam_sodar.py --undefined /pam_sodar.py.j2
        echo "Set up PAM file"
        j2 -o /etc/pam.d/irods --undefined /irods.pam.j2

    fi

    find /var/lib/irods -not -path '/var/lib/irods/Vault*' -exec chown $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER {} \;

    # Generate .irodsA
    echo "Prepare service account"
    set +e
    su - irods -c "echo ${IRODS_ADMIN_PASS} | iinit > /dev/null 2>&1"
    set -e

    # Start iRODS
    echo "Start iRODS"
    /etc/init.d/irods start

    # Wait for iRODS server to become available
    while ! nc -w 1 $IRODS_HOST_NAME $IRODS_ZONE_PORT &> /dev/null; do
        echo "Waiting for iRODS server ..."
        /etc/init.d/irods status
        sleep 5
    done
    sleep 5

    # Set minimum session timeout
    if [[ "$IRODS_ROLE" == "provider" ]]; then
        su - irods -c "iadmin set_grid_configuration authentication password_min_time ${IRODS_PASSWORD_MIN_TIME}"
    fi

    echo "iRODS is ready"
    sleep infinity

fi

exec "$@"

#!/bin/bash

NO_WAIT=${NO_WAIT-0}
export PGPASSWORD=$IRODS_ICAT_DBPASS
set -euo pipefail

if [[ "$1" == "irods-start" ]]; then

    if [[ ! -e /etc/irods/core.py.template ]]; then
        cp /core.py.template /etc/irods/core.py.template
    fi

    chmod a+x /var/lib/irods/irodsctl
    chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER /etc/irods
    sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
    chown syslog:adm /var/log/irods
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
        # DEBUG
        # cat /unattended_config.json

        echo "Perform iRODS setup"
        python3 /var/lib/irods/scripts/setup_irods.py --json_configuration_file=/unattended_config.json

        cp /var/lib/irods/.irods/irods_environment.json /etc/irods/irods_environment.json
        cp /var/lib/irods/.odbc.ini /etc/irods/.odbc.ini
        cp -f /var/lib/irods/version.json /etc/irods/version.json

        # Enable the python rule engine
        if [ -f /irods_python-re_installer.py ]; then
            echo "Enable python rule engine"
            python3 ./irods_python-re_installer.py
        fi

        touch /etc/irods/.provisioned
    fi

    echo "Set up custom PAM module"
    mkdir -p /usr/local/lib/pam-sodar
    j2 -o /usr/local/lib/pam-sodar/pam_sodar.py --undefined /pam_sodar.py.j2
    echo "Set up PAM file"
    j2 -o /etc/pam.d/irods --undefined /irods.pam.j2

    find /var/lib/irods -not -path '/var/lib/irods/Vault*' -exec chown $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER {} \;

    # Start iRODS
    echo "Start iRODS"
    /etc/init.d/irods start

    # Wait for iCAT port to become available
    while ! nc -w 1 $IRODS_HOST_NAME $IRODS_ZONE_PORT &> /dev/null; do
        echo "Waiting for iCAT server ..."
        /etc/init.d/irods status
        sleep 5
    done
    sleep 5

    echo "Test iinit"
    su - irods -c "/irods_login.sh ${IRODS_ADMIN_PASS}"

    echo "iCAT at ${IRODS_HOST_NAME} ready!"

    sleep infinity

fi

exec "$@"

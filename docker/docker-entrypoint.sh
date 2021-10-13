#!/bin/bash

NO_WAIT=${NO_WAIT-0}
export WAIT_HOSTS=${WAIT_HOSTS-${IRODS_ICAT_DBSERVER}:${IRODS_ICAT_DBPORT}}

# TODO: Add support for resc-only
if [[ "$1" == "icat-enabled" ]] || [[ "$1" == "resc-only" ]]; then

    if [[ ! -e /etc/irods/core.py.template ]]; then
        cp /core.py.template /etc/irods/core.py.template
    fi

    chmod a+x /var/lib/irods/irodsctl
    chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER /etc/irods

    if [[ "$NO_WAIT" -ne 1 ]]; then
        /usr/local/bin/wait

        if [ -z "$DATABASE_URL" ]; then
            PGPASSWORD=$IRODS_ICAT_DBPASS
            PSQL="pg_isready -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT"
        else
            PSQL="pg_isready -d $IRODS_ICAT_DBSERVER"
        fi
    fi

    if [ -f /etc/irods/.provisioned ]; then

        echo "Skipping iRODS provisioning ..."

        if [ ! -f /var/lib/irods/.irods/irods_environment.json ]; then
            mkdir -p /var/lib/irods/.irods
            cp /etc/irods/irods_environment.json /var/lib/irods/.irods/irods_environment.json
        fi

        if [ ! -f /var/lib/irods/.odbc.ini ]; then
            cp /etc/irods/.odbc.ini /var/lib/irods/.odbc.ini
        fi

    else

        echo "Provisioning iRODS ..."

        echo "Pre-create database if necessary"
        echo $IRODS_ICAT_DBPASS \
        | createdb -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT -U $IRODS_ICAT_DBUSER -W ICAT

        echo "Set up unattended configuration file"
        j2 -o /unattended_config.json --undefined --filters=j2-filters.py unattended_config.json.j2

        echo "Perform iRODS setup"
        python /var/lib/irods/scripts/setup_irods.py --json_configuration_file=/unattended_config.json

        cp /var/lib/irods/.irods/irods_environment.json /etc/irods/irods_environment.json
        cp /var/lib/irods/.odbc.ini /etc/irods/.odbc.ini

        # Enable the python rule engine
        if [ -f /irods_python-re_installer.py ]; then
            echo "Enable python rule engine"
            ./irods_python-re_installer.py
        fi

        touch /etc/irods/.provisioned
    fi

    find /var/lib/irods -not -path '/var/lib/irods/Vault*' -exec chown -c $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER {} \;

    # Restart iRODS after setup
    echo "Restart iRODS"
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

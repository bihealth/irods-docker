#!/bin/bash

NO_WAIT=${NO_WAIT-0}
export WAIT_HOSTS=${WAIT_HOSTS-postgres:5432}

if [[ "$1" == "icat-enabled" ]] || [[ "$1" == "resc-only" ]]; then

    if [[ ! -e /etc/irods/core.py.template ]]; then
        cp /core.py.template /etc/irods/core.py.template
    fi

    chmod a+x /var/lib/irods/irodsctl

    if [[ "$NO_WAIT" -ne 1 ]]; then
        /usr/local/bin/wait

        if [ -z "$DATABASE_URL" ]; then
            PGPASSWORD=$IRODS_ICAT_DBPASS
            PSQL="pg_isready -h $IRODS_ICAT_DBSERVER -p 5432 -U $IRODS_ICAT_DBUSER"
        else
            PSQL="pg_isready -d $IRODS_ICAT_DBSERVER"
        fi
    fi

    if [ -f /etc/irods/.provisioned ]; then

        echo "skipping iRODS provisioning ..."

        if [ ! -f /var/lib/irods/.irods/irods_environment.json ]; then
            mkdir -p /var/lib/irods/.irods
            cp /etc/irods/irods_environment.json /var/lib/irods/.irods/irods_environment.json
        fi

        if [ ! -f /var/lib/irods/.odbc.ini ]; then
            cp /etc/irods/.odbc.ini /var/lib/irods/.odbc.ini
        fi

    else

        echo "provisioning iRODS ..."
        /genresp.sh "$1" /response.txt

        echo "pre-create database if necessary"
        echo $IRODS_ICAT_DBPASS \
        | createdb -h $IRODS_ICAT_DBSERVER -p 5432 -U $IRODS_ICAT_DBUSER -W ICAT

        echo "set up unattended configuration file"
        # TODO: Set up from template and env vars

        echo "perform iRODS setup"
        cat /response.txt | python /var/lib/irods/scripts/setup_irods.py --json_configuration_file=/unattended_config.json

        cp /var/lib/irods/.irods/irods_environment.json /etc/irods/irods_environment.json
        cp /var/lib/irods/.odbc.ini /etc/irods/.odbc.ini

        ## enable the python rule engine
        if [ -f /irods_python-re_installer.py ]; then
            ./irods_python-re_installer.py
        fi

        touch /etc/irods/.provisioned
    fi

    find /var/lib/irods -not -path '/var/lib/irods/Vault*' -exec chown -c irods:irods {} \;
    chown -cR irods:irods /etc/irods

    /etc/init.d/irods restart

    # Wait for iCAT port to become available
    while ! nc -w 1 $(hostname) 1247 &> /dev/null; do
        echo "waiting for icat server ..."
        sleep 5
    done
    sleep 5

    su - irods -c "/irods_login.sh ${IRODS_ADMIN_PASS}"

    echo "iCAT ${HOSTNAME} ready!"

    sleep infinity
fi

exec "$@"

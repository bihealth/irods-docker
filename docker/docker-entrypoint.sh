#!/bin/bash

NO_WAIT=${NO_WAIT-0}
export PGPASSWORD=$IRODS_ICAT_DBPASS
set -euo pipefail

if [[ "$1" == "irods-start" ]]; then

    # Remove systemd-timesyncd due to a possible conflict between the irods
    # service account and this package's service account uid (see #93)
    if [[ "$PURGE_SYSTEMD_TIMESYNCD" == "1" ]] && id -u systemd-timesync 2> /dev/null; then
        apt purge -y systemd-timesyncd
        userdel systemd-timesync
    fi

    # Set up service user and permissions
    groupadd -f -g $IRODS_SERVICE_ACCOUNT_GID $IRODS_SERVICE_ACCOUNT_GROUP
    useradd -d /var/lib/irods -s /bin/bash -u $IRODS_SERVICE_ACCOUNT_UID -g $IRODS_SERVICE_ACCOUNT_GID $IRODS_SERVICE_ACCOUNT_USER || true
    chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER /etc/irods

    # Set up log file
    mkdir -p /var/log/irods
    touch /var/log/irods/irods.log
    chown -R syslog:adm /var/log/irods

    echo "iRODS server role: $IRODS_ROLE"

    if [[ "$IRODS_ROLE" == "provider" ]] && [[ "$NO_WAIT" -ne 1 ]]; then
        echo "Waiting for postgres.."
        export WAIT_HOSTS=${WAIT_HOSTS-${IRODS_ICAT_DBSERVER}:${IRODS_ICAT_DBPORT}}
        /usr/local/bin/wait
    fi

    if [ -f /etc/irods/.provisioned ]; then

        echo "Skipping iRODS provisioning.."

        if [ ! -f /var/lib/irods/.irods/irods_environment.json ]; then
            mkdir -p /var/lib/irods/.irods
            cp /etc/irods/irods_environment.json /var/lib/irods/.irods/irods_environment.json
        fi

        if [ -f /etc/irods/.odbc.ini ] && [ ! -f /var/lib/irods/.odbc.ini ]; then
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
                createdb -h $IRODS_ICAT_DBSERVER -p $IRODS_ICAT_DBPORT -U $IRODS_ICAT_DBUSER $IRODS_ICAT_DBNAME
            fi

        fi

        echo "Create iRODS resource directory and set service account as owner"
        mkdir -p $IRODS_RESOURCE_DIRECTORY
        chown -cR $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER $IRODS_RESOURCE_DIRECTORY

        echo "Set up unattended configuration file"
        j2 -o /unattended_config.json unattended_config.json.j2

        echo "Set up rule file for the Python rule engine"
        j2 -o /core.py --undefined core.py.j2
        cp -f /core.py /etc/irods/core.py

        echo "Perform iRODS setup"
        python3 /var/lib/irods/scripts/setup_irods.py --json_configuration_file=/unattended_config.json

        cp /var/lib/irods/.irods/irods_environment.json /etc/irods/irods_environment.json

        if [ -f /var/lib/irods/.odbc.ini ]; then
            cp /var/lib/irods/.odbc.ini /etc/irods/.odbc.ini
        fi

        cp -f /var/lib/irods/version.json /etc/irods/version.json

        touch /etc/irods/.provisioned

    fi

    if [[ "$IRODS_ROLE" == "provider" ]]; then
        echo "Set up custom PAM module"
        j2 -o /etc/pam.d/irods /irods.pam.j2
    fi

    find /var/lib/irods -not -path '/var/lib/irods/Vault*' -exec chown $IRODS_SERVICE_ACCOUNT_GROUP:$IRODS_SERVICE_ACCOUNT_USER {} \;

    # Start the cron daemon (required by logrotate)
    cron

    # Start the rsyslog daemon (see /var/log/irods/irods.log)
    rsyslogd -iNONE

    # Generate .irodsA by running iinit. Although the command will fail because
    # the server is not running, we expect it to create the .irodsA file and to
    # print an error message that says "Saved password [...]". If the .irodsA is
    # not detected, the script will exit immediately. Generating .irodsA must be
    # done before starting the server, otherwise the first iinit after starting
    # the server will time-out.
    echo "Prepare service account"
    su - irods -c "echo \"${IRODS_ADMIN_PASS}\" | iinit > /dev/null 2>&1" || test -f /var/lib/irods/.irods/.irodsA

    # Start iRODS
    echo "Start iRODS v$IRODS_PKG_VERSION"
    /etc/init.d/irods start

    # Wait for iRODS server to become available, as suggested in the docs:
    # https://docs.irods.org/4.3.5/system_overview/tips_and_tricks/#monitoring-status-of-irods-servers
    heartbeat_cmd="echo -e '\x00\x00\x00\x33<MsgHeader_PI><type>HEARTBEAT</type></MsgHeader_PI>' | \
        (exec 3<>/dev/tcp/127.0.0.1/${IRODS_ZONE_PORT}; cat >&3; cat <&3; exec 3<&-)"
    while [[ $(bash -c "$heartbeat_cmd") != "HEARTBEAT" ]]; do
        echo "Waiting for iRODS server ..."
        /etc/init.d/irods status
        sleep 5
    done
    sleep 5

    # Set minimum session timeout
    if [[ "$IRODS_ROLE" == "provider" ]]; then
        echo "Updating minimum session timeout"
        su - irods -c "iadmin set_grid_configuration authentication password_min_time ${IRODS_PASSWORD_MIN_TIME}"
    fi

    echo "iRODS is ready"

    set +e
    set +o pipefail

    JQ_FILTER='try fromjson catch null | select(. != null) | "[\(.server_timestamp)] \(.log_level) \(.log_category): \(.log_message)"'

    exec tail -F /var/log/irods/irods.log | jq -R --unbuffered -r "$JQ_FILTER"
fi

exec "$@"

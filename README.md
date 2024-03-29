# Dockerized iRODS

This repository contains the necessary files to build an iRODS Docker image based on Ubuntu 18.04.
The code is based on [hurngchunlee/docker-irods](https://github.com/hurngchunlee/docker-irods).

The image contains features specific to our [SODAR](https://github.com/bihealth/sodar-server) system, but using them is optional and the image also works as a generic iRODS server.

## Building

```bash
$ cd docker
$ docker build .
```

## Data Persistency

Each container exposes volumes for data persistency. The list of volumes are provided in the table below:

| path in container               | usage                         |
|---------------------------------|-------------------------------|
| /etc/irods                      | resource server configuration |
| /var/lib/irods/iRODS/server/log | resource server log           |

For iRODS services, the setup script (`/var/lib/irods/scripts/setup_irods.py`) is only executed when the file `/etc/irods/.provisioned` is not present.
The file `/etc/irods/.provisioned` is created when the setup script is executed successfully.

## Commands

The following commands are available.
If you specify anything else then the startup script will `exec` this command (e.g., `bash`).

- `irods-start` (default) -- Start iRODS server

## Environment Variables

There are several environment variables can be set for setting up iRODS.
The variables are feeded into the iRODS setup script (`/var/lib/irods/scripts/setup_irods.py`) for the first startup.
They are summarised below.
iRODS can be run in either "provider" mode, which installs an iCAT catalogue server, or "consumer" mode which only installs a resource server to be used with a remote iRODS provider. The "Role" column shows for which role(s) each variable is used.

| Variable name                    | Default Value                    | Role       |
|----------------------------------|----------------------------------|------------|
| IRODS_PKG_VERSION                | 4.2.8-1                          | both       |
| IRODS_ROLE                       | provider                         | both       |
| IRODS_HOST_NAME                  | localhost                        | both       |
| IRODS_SERVICE_ACCOUNT_USER       | irods                            | both       |
| IRODS_SERVICE_ACCOUNT_GROUP      | irods                            | both       |
| IRODS_ADMIN_USER                 | rods                             | both       |
| IRODS_ADMIN_PASS                 | rods                             | both       |
| IRODS_ZONE_NAME                  | demoZone                         | both       |
| IRODS_ZONE_PORT                  | 1247                             | both       |
| IRODS_ZONE_KEY                   | TEMPORARY_zone_key               | both       |
| IRODS_NEGOTIATION_KEY            | TEMPORARY_32byte_negotiation_key | both       |
| IRODS_CONTROL_PLANE_PORT         | 1248                             | both       |
| IRODS_CONTROL_PLANE_KEY          | TEMPORARY__32byte_ctrl_plane_key | both       |
| IRODS_DATA_PORT_RANGE_START      | 20000                            | both       |
| IRODS_DATA_PORT_RANGE_END        | 20199                            | both       |
| IRODS_SSL_CERTIFICATE_CHAIN_FILE | /etc/irods/server.crt            | both       |
| IRODS_SSL_CERTIFICATE_KEY_FILE   | /etc/irods/server.key            | both       |
| IRODS_SSL_DH_PARAMS_FILE         | /etc/irods/dhparams.pem          | both       |
| IRODS_SSL_VERIFY_SERVER          | none                             | both       |
| IRODS_PASSWORD_SALT              | tempsalt                         | both       |
| IRODS_SSL_CA_CERT_PATH           |                                  | both       |
| IRODS_AUTHENTICATION_SCHEME      | native                           | both       |
| IRODS_CLIENT_SERVER_NEGOTIATION  | off                              | both       |
| IRODS_CLIENT_SERVER_POLICY       | CS_NEG_REFUSE                    | both       |
| IRODS_RESOURCE_DIRECTORY         | /data/Vault                      | both       |
| IRODS_DEFAULT_HASH_SCHEME        | SHA256                           | both       |
| IRODS_ODBC_DRIVER                | PostgreSQL Unicode               | provider   |
| IRODS_ICAT_DBSERVER              | postgres                         | provider   |
| IRODS_ICAT_DBPORT                | 5432                             | provider   |
| IRODS_ICAT_DBNAME                | ICAT                             | provider   |
| IRODS_ICAT_DBUSER                | irods                            | provider   |
| IRODS_ICAT_DBPASS                | irods                            | provider   |
| IRODS_SSSD_AUTH                  | 0                                | provider   |
| IRODS_SODAR_AUTH                 | 0                                | provider   |
| IRODS_CATALOG_PROVIDER_HOST      |                                  | consumer   |

## SSSD Support

In addition to the base image, we provide the images `${VERSION}-sssd` (e.g., `4.2.11-1-sssd`) which have SSSD installed.
You will have to share `/var/lib/sss` between the SSSD container and iRODS so both containers can communicate.

In our installations, we run [bihealth/sssd-docker](https://github.com/bihealth/sssd-docker) in a second container.

## Troubleshooting

A previous version of this image was built on CentOS7 instead of Ubuntu. If updating or redeploying an existing installation, you may encounter the following error connecting to the iRODS database: `[unixODBC][Driver Manager]Data source name not found, and no default driver specified`

To fix this, first edit the file `/etc/irods/server_config.json`. Find the variable `db_odbc_driver` and change its value from `PostgreSQL` to `PostgreSQL Unicode`.

Next, do the same modification for the environment variable `IRODS_ODBC_DRIVER`. After restarting the image, iRODS should work normally.

# Dockerized iRODs

This repository contains the necessary files to build a Docker image for iRODS.
The code is based on [hurngchunlee/docker-irods](https://github.com/hurngchunlee/docker-irods).

## What's this?

This is a Docker image from CUBI @bihealth that we use for our iRODS deployment.
It is based on the great work in [hurngchunlee/docker-irods](https://github.com/hurngchunlee/docker-irods).
We simplified things a bit and publish the results on this repository's packages as a Docker image.

### SSSD Support

Also, we provide the images `${VERSION}-sssd` (e.g., `latest-sssd`) that have SSSD installed.
You will have to share `/var/lib/sss` between the SSSD container and iRODS so both containers can communicate.

In our installations, we run [bihealth/sssd-docker](https://github.com/bihealth/sssd-docker) in a second container.

## Building

```bash
$ cd docker
$ docker build .
```

## Data Persistency

Each container exposes volumes for data persistency.
The list of volumes are provided in the table below:

| path in container               | usage                         |
|---------------------------------|-------------------------------|
| /etc/irods                      | resource server configuration |
| /var/lib/irods/iRODS/server/log | resource server log           |


For iRODS services, the setup script (`/var/lib/irods/scripts/setup_irods.py`) is only executed when the file `/etc/irods/.provisioned` is not presented.
The file `/etc/irods/.provisioned` is also created when the setup script is executed successfully.

## Commands

The following commands are available.
If you specify anything else then the startup script will `exec` this command (e.g., `bash`).

- `irods-start` (default) -- Start iRODS server

## Environment Variables

There are several environment variables can be set for setting up iRODS.
The variables are feeded into the iRODS setup script (`/var/lib/irods/scripts/setup_irods.py`) for the first startup.
They are summarised below.
iRODS can be run in either "provider" mode, which installs an iCAT catalogue server, or "consumer" mode which only installs a resource server to be used with a remote iRODS provider. The "provider" column shows whether the variable is only required in the provider role.

| Variable name                   | Default Value                    | Provider   |
|---------------------------------|----------------------------------|------------|
| IRODS_PKG_VERSION               | 4.2.8-1                          | no         |
| IRODS_ROLE                      | provider                         | no         |
| IRODS_HOST_NAME                 | localhost                        | no         |
| IRODS_SERVICE_ACCOUNT_USER      | irods                            | no         |
| IRODS_SERVICE_ACCOUNT_GROUP     | irods                            | no         |
| IRODS_ADMIN_USER                | rods                             | no         |
| IRODS_ADMIN_PASS                | rods 							 | no         |
| IRODS_ZONE_NAME                 | demoZone                         | no         |
| IRODS_ZONE_PORT                 | 1247                             | no         |
| IRODS_ZONE_KEY                  | TEMPORARY_zone_key               | no         |
| IRODS_NEGOTIATION_KEY           | TEMPORARY_32byte_negotiation_key | no         |
| IRODS_CONTROL_PLANE_PORT        | 1248                             | no         |
| IRODS_CONTROL_PLANE_KEY         | TEMPORARY__32byte_ctrl_plane_key | no         |
| IRODS_DATA_PORT_RANGE_START     | 20000                            | no         |
| IRODS_DATA_PORT_RANGE_END       | 20199                            | no         |
| IRODS_SSL_VERIFY_SERVER         | none                             | no         |
| IRODS_PASSWORD_SALT             | tempsalt                         | no         |
| IRODS_SSL_CA_CERT_PATH          |                                  | no         |
| IRODS_AUTHENTICATION_SCHEME     | native                           | no         |
| IRODS_CLIENT_SERVER_NEGOTIATION | off                              | no         |
| IRODS_CLIENT_SERVER_POLICY      | CS_NEG_REFUSE                    | no         |
| IRODS_RESOURCE_DIRECTORY        | /data/Vault                      | no         |
| IRODS_ODBC_DRIVER               | PostgreSQL                       | yes        |
| IRODS_ICAT_DBSERVER             | postgres                         | yes        |
| IRODS_ICAT_DBPORT               | 5432                             | yes        |
| IRODS_ICAT_DBNAME               | ICAT                             | yes        |
| IRODS_ICAT_DBUSER               | irods                            | yes        |
| IRODS_ICAT_DBPASS               | test123                          | yes        |
| IRODS_CATALOG_PROVIDER_HOST     | localhost                        | no         |

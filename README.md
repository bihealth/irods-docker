# Dockerized iRODS

This repository contains the necessary files to build an iRODS Docker image based on Ubuntu 20.04.
The code is based on [hurngchunlee/docker-irods](https://github.com/hurngchunlee/docker-irods).

The image contains features specific to our [SODAR](https://github.com/bihealth/sodar-server) system, but using them is optional and the image also works as a generic iRODS server.

This image uses the Python rule engine for rules. For enabling legacy or C++ engines, the user needs to provide their own rule files and add relevant changes to `server_config.json`.

Images are built and tagged for a specific iRODS release. The most recent build is tested to be compatible with iRODS version `4.3.3`. Our goal is to keep up with the most recent major release of iRODS. Updates for older major versions will not be made.

**NOTE:** Images built for iRODS v4.3.x are **not** compatible with iRODS v4.2 or below. See below for instructions on upgrading from an older iRODS v4.2 build of this image.


## Data Persistency

Each container exposes volumes for data persistency. The list of volumes are provided in the table below:

| path in container               | usage                           |
|---------------------------------|---------------------------------|
| /etc/irods                      | Server configuration            |

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
| IRODS_PKG_VERSION                | 4.3.3                            | both       |
| IRODS_PYTHON_RULE_ENGINE_VERSION | 4.3.3.0-0+4.3.3                  | both       |
| IRODS_ROLE                       | provider                         | both       |
| IRODS_HOST_NAME                  | localhost                        | both       |
| IRODS_SERVICE_ACCOUNT_USER       | irods                            | both       |
| IRODS_SERVICE_ACCOUNT_GROUP      | irods                            | both       |
| IRODS_SERVICE_ACCOUNT_UID        | 1000                             | both       |
| IRODS_SERVICE_ACCOUNT_GID        | 1000                             | both       |
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
| IRODS_CLIENT_SERVER_NEGOTIATION  | request_server_negotiation       | both       |
| IRODS_CLIENT_SERVER_POLICY       | CS_NEG_REFUSE                    | both       |
| IRODS_DEFAULT_RESOURCE_NAME      | demoResc                         | both       |
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
| IRODS_PASSWORD_MIN_TIME          | 1209600                          | provider   |
| IRODS_CATALOG_PROVIDER_HOST      |                                  | consumer   |


## SSSD Support

In addition to the base image, we provide the images `${VERSION}-sssd` (e.g., `4.3.3-1-sssd`) which have SSSD installed.
You will have to share `/var/lib/sss` between the SSSD container and iRODS so both containers can communicate.

In our installations, we run [bihealth/sssd-docker](https://github.com/bihealth/sssd-docker) in a second container.


## Upgrading From iRODS 4.2

See [sodar-docker-compose](https://github.com/bihealth/sodar-docker-compose/) for upgrade instructions.


## Troubleshooting

### v4.3

Releases of this image for iRODS v4.3.x require PostgreSQL v12 or newer. Installations with PostgreSQL v11 no longer work.

### v4.2

A previous version of this image was built on CentOS7 instead of Ubuntu. If updating or redeploying an existing installation, you may encounter the following error connecting to the iRODS database: `[unixODBC][Driver Manager]Data source name not found, and no default driver specified`

To fix this, first edit the file `/etc/irods/server_config.json`. Find the variable `db_odbc_driver` and change its value from `PostgreSQL` to `PostgreSQL Unicode`.

Next, do the same modification for the environment variable `IRODS_ODBC_DRIVER`. After restarting the image, iRODS should work normally.


## Building (for Developers)

To build the image, use the following command:

```
bash
$ IRODS_PKG_VERSION=x.x.x IRODS_PYTHON_RULE_ENGINE_VERSION=y.y.y BUILD_VERSION=z ./build.sh
```

Releases and images are tagged with the iRODS server version followed by the image build version. This means that e.g. the initial release for iRODS `4.3.3` will be tagged as `4.3.3-1`. Fixes or improvements to that release would then be published as `4.3.3-2`.

Note that if you are providing a non-default iRODS version, you will also have to provide the `irods-rule-engine-plugin-python` version number with the `IRODS_PYTHON_RULE_ENGINE_VERSION` env var. This package does not follow the same versioning conventions as the main iRODS packages. The value is expected to be the full version name *without* the `~focal` suffix. You can find the available versions e.g. by running `apt-cache madison irods-rule-engine-plugin-python`.

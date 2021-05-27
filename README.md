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
| /var/lib/irods/Vault            | resource server data vault    |

For iRODS services, the setup script (`/var/lib/irods/scripts/setup_irods.py`) is only executed when the file `/etc/irods/.provisioned` is not presented.
The file `/etc/irods/.provisioned` is also created when the setup script is executed successfully.

## Commands

The following commands are available.
If you specify anything else then the startup script will `exec` this command (e.g., `bash`).

- `icat-enabled` (default) -- run as iCAT enabled iRODS resource server
- `resc-only` -- run as iRODS resource server only

## Environment Variables

There are several environment variables can be set for setting up iRODS.
The variables are feeded into the iRODS setup script (`/var/lib/irods/scripts/setup_irods.py`) for the first startup.
They are summarised below.
The "only iCAT" column shows whether the variable is required in the icat-enabled instanced only.

|   variable name           | default value                    | only iCAT? |
|---------------------------|----------------------------------|------------|
| IRODS_ICAT_DBSERVER       | icat-db                          | yes |
| IRODS_ICAT_DBPORT         | 5432                             | yes |
| IRODS_ICAT_DBNAME         | ICAT                             | yes |
| IRODS_ICAT_DBUSER         | irods                            | yes |  
| IRODS_ICAT_DBPASS         | test123                          | yes |
| IRODS_ZONE_NAME           | rdmtst                           | no | 
| IRODS_ZONE_PORT           | 1247                             | no | 
| IRODS_DATA_PORT_RANGE_BEG | 20000                            | no | 
| IRODS_DATA_PORT_RANGE_END | 20199                            | no | 
| IRODS_CONTROLPLAN_PORT    | 1248                             | no | 
| IRODS_ADMIN_USER          | rods                             | no | 
| IRODS_ADMIN_PASS          | rods 							   | no | 
| IRODS_ZONE_KEY            | TEMPORARY_zone_key               | no | 
| IRODS_NEGOTIATION_KEY     | TEMPORARY_32byte_negotiation_key | no | 
| IRODS_CONTROLPLANE_KEY    | TEMPORARY__32byte_ctrl_plane_key | no | 

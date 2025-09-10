# Changelog

## Unreleased

- Upgrade to iRODS v4.3.4 (#62)
- Fix `LegacyKeyValueFormat` warning on build (#67)

## v4.3.3-2 (2025-02-20)

- Add `IRODS_DEFAULT_RESOURCE_NAME` env var (#17)
- Add `IRODS_SERVICE_ACCOUNT_UID` and `IRODS_SERVICE_ACCOUNT_GID` env vars (#50)
- Update unattended config for consumer installs (#49)
- Update entrypoint to skip custom PAM module setup for consumer installs (#52)
- Update entrypoint to clarify iRODS server wait messages (#53)
- Move service user and resource directory setup in entrypoint (#54)
- Fix `.odbc.ini` file handling on resource server (#55)

## v4.3.3-1 (2024-12-19)

- Upgrade to iRODS v4.3.3 (#16)
- Upgrade to PostgreSQL >11 (#18)
- Upgrade image to Ubuntu 20.04 (#19)
- Upgrade scripts for Python3 (#21)
- Set up logging with syslog (#16, #34, #36, #37)
- Enable setting `irods-rule-engine-plugin-python` version in `build.sh` (#27)
- Add changelog (#22)
- Change custom SODAR PAM login method from `POST` to `GET` (bihealth/sodar-server#1999)
- Set bash as shell for `IRODS_SERVICE_ACCOUNT_USER` (#15)
- Add `BUILD_VERSION` in `build.sh` (#23)
- Update minimum password time configuration (#33)
- Add `IRODS_PASSWORD_MIN_TIME` env var (#33)
- Fix SSSD package discovery (#31)
- Enable Python rule engine `core.py` file templating (#41)
- Add `IRODS_CLIENT_SERVER_POLICY` in `core.py` template (#42)
- Remove support for legacy and C++ rule engines (#43)
- Remove `IRODS_AUTHENTICATION_SCHEME` env var (#44)
- Set `IRODS_CLIENT_SERVER_NEGOTIATION` default value to `request_server_negotiation` (#45)

## v4.2 (2024-01-19)

- Tag release for legacy iRODS v4.2 image

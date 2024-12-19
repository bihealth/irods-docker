# Changelog

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

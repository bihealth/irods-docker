"""
PAM module for authentication against SODAR users, to be used if an external
LDAP/AD server is not available.
"""

__author__ = 'Mikko Nieminen'

import os
import requests


def pam_sm_authenticate(pamh, flags, argv):
    """Implement the pam_authenticate(3) interface."""
    pamh.authtok = pamh.conversation(
        pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, 'Password:')
    ).resp

    sodar_host = os.environ.get('IRODS_SODAR_API_HOST', 'https://sodar-web')
    url = sodar_host + '/irodsbackend/api/auth'
    verify = int(os.environ.get('IRODS_SODAR_AUTH_VERIFY', '1'))

    response = requests.post(
        url, auth=(pamh.user, pamh.authok), verify=verify
    )
    if response.status_code == 200:
        return pamh.PAM_SUCCESS
    return pamh.PAM_AUTH_ERR


def pam_sm_setcred(pamh, flags, argv):
    """This service does not implement the pam_setcred(3) interface."""
    return pamh.PAM_CRED_UNAVAIL

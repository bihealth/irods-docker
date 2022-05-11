"""
PAM module for authentication against SODAR users, to be used if an external
LDAP/AD server is not available.
"""
__author__ = 'Mikko Nieminen'

import os
import requests


def pam_sm_authenticate(pamh, flags, argv):
    """Implement the pam_authenticate(3) interface."""
    a = pamh.conversation(
        pamh.Message(pamh.PAM_PROMPT_ECHO_OFF, 'SODAR password: ')
    ).resp

    sodar_host = os.environ.get('IRODS_SODAR_API_HOST', 'http://sodar-web:8080')
    url = sodar_host + '/irodsbackend/api/auth'

    response = requests.post(url, auth=(pamh.user, a))
    if response.status_code == 200:
        return pamh.PAM_SUCCESS
    return pamh.PAM_AUTH_ERR


def pam_sm_setcred(pamh, flags, argv):
    """This service does not implement the pam_setcred(3) interface."""
    return pamh.PAM_CRED_UNAVAIL

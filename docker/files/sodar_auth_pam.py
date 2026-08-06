#!/usr/bin/env python3

# This script authenticates a user against SODAR. The SODAR host is taken from
# the command-line arguments. The script expects the username to be provided
# in the PAM_USER environment variable, and it reads the password from stdin.
# Then, it contacts the authentication endpoint in SODAR using the provided
# credentials, and, if SODAR authentication is successful, it exits with 0. If
# authentication fails, the exit code is 1. We can consider using different
# codes for different failure modes.
#
# The script is meant to be used in conjunction with the pam_exec module.
# For example, add this to the PAM config:
# 
#     auth       sufficient pam_exec.so expose_authtok type=auth /path/to/sodar_auth_pam.py https://sodar-web:8000

import argparse
import os
import requests

parser = argparse.ArgumentParser(
    description='Authenticate a user against SODAR through pam_exec.'
)
parser.add_argument(
    'sodar_api_host',
    type=str,
    help='URL of the SODAR host (e.g. https://sodar-web:8080)',
)
args = parser.parse_args()

user = os.environ.get('PAM_USER')
password = input()
url = args.sodar_api_host + '/irodsbackend/api/auth'

response = requests.get(url, auth=(user, password))
if response.status_code == 200:
    exit(0)
exit(1)

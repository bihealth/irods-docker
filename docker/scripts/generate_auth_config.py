#!/usr/bin/env python3

from configure_server import render

if __name__ == '__main__':
    render(
        'irods.pam.j2',
        '/etc/pam.d/irods',
    )

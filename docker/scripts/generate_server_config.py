#!/usr/bin/env python3

import jinja2
import os
import socket


environment = jinja2.Environment(
    loader=jinja2.FileSystemLoader('/templates')
)


def render(template_in: str, file_out: str, **kwargs):
    """Renders a template to a file substituting environment variables

    :param template_in: path to template file
    :param file_out: path to output file
    :param kwargs: key-value pairs in addition to the system environment
    """
    template = environment.get_template(template_in)
    content = template.render(
        os.environ,
        **kwargs,
    )
    with open(file_out, 'w') as f:
        f.write(content)


if __name__ == '__main__':
    # Server config
    render(
        'unattended_config.json.j2',
        '/tmp/unattended_config.json', 
        IRODS_HOST_NAME=socket.gethostname(),
    )
    # Core rules for the Python engine
    render(
        'core.py.j2',
        '/etc/irods/core.py',
    )

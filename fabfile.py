# coding: utf-8

# Usage:
#
# fab setup:<client>,<server>,local_port=<local_port>,remote_port=<remote_port>

import io
import re
import os.path

from fabric.api import run, settings, task
from cuisine import (user_ensure, dir_ensure, ssh_keygen, ssh_authorize,
        package_ensure, upstart_ensure, file_read, file_write, file_exists,
        mode_sudo, text_ensure_line)

@task
def setup(client, server, local_port, remote_port, remote_host='localhost',
        direction='local', ssh_host=None, ssh_port=None,
        service_name='autossh', service_user='autossh'):
    """
    Setup permanent SSH tunnel from client to server.
    """

    user, host, port = _parse_host_string(server)
    ssh_host = ssh_host or host # server's hostname resolvable from client
    ssh_port = ssh_port or port

    home_dir = '/var/lib/%s' % service_user

    with settings(host_string=client):
        client_install_autossh()
        client_create_service(local_port, remote_port, remote_host,
                direction, ssh_host, ssh_port, service_name, service_user)

        create_user(service_user, home_dir)
        pubkey = client_generate_pubkey(service_user)
        client_insert_known_host(user, home_dir, ssh_host, ssh_port)

    with settings(host_string=server):
        create_user(service_user, home_dir)
        server_insert_pubkey(service_user, pubkey)

    with settings(host_string=client):
        client_start_service(service_name)

def client_install_autossh():
    package_ensure('autossh')

def client_create_service(local_port, remote_port, remote_host,
        direction, ssh_host, ssh_port, service_name, user):

    file_path = '/etc/init/%s.conf' % service_name

    here = os.path.abspath(os.path.dirname(__file__))
    with io.open(os.path.join(here, 'upstart_template.conf')) as f:
        content = f.read()

    autossh_opts = '-nNT'

    if direction == 'local':
        autossh_opts += ' -L'
    elif direction == 'remote':
        autossh_opts += ' -R'
    else:
        raise Exception('Invalid direction')

    autossh_opts += ' %s:%s:%s' % (local_port, remote_host, remote_port)

    autossh_opts += ' %s@%s' % (user, ssh_host)

    if ssh_port:
        autossh_opts += ' -p %s' % (ssh_port, )

    content = content % {
            'user': user,
            'group': user,
            'autossh_opts': autossh_opts,
        }

    content = content.encode('utf-8')

    file_write(file_path, content, mode='644', owner='root', group='root',
            sudo=True)

def create_user(user, home_dir):
    user_ensure(user, home=home_dir)
    with mode_sudo():
        dir_ensure(home_dir, mode='755', owner=user, group=user)

def client_generate_pubkey(user):
    with mode_sudo():
        pubkey_path = ssh_keygen(user, keytype='rsa')
        pubkey = file_read(pubkey_path)

    return pubkey

def client_insert_known_host(user, home_dir, ssh_host, ssh_port):
    host_key = run('ssh-keyscan %s 2>/dev/null' % ssh_host)
    assert host_key

    known_hosts_path = '%s/.ssh/known_hosts' % home_dir

    with mode_sudo():
        if file_exists(known_hosts_path):
            known_hosts = file_read(known_hosts_path)
            new_known_hosts = text_ensure_line(known_hosts, host_key.rstrip())
            if new_known_hosts == known_hosts:
                return
        else:
            new_known_hosts = host_key

        file_write(known_hosts_path, new_known_hosts, mode='644',
                owner=user, group=user, sudo=True)

def server_insert_pubkey(user, pubkey):
    with mode_sudo():
        ssh_authorize(user, pubkey)

def client_start_service(service_name):
    upstart_ensure(service_name)

def _parse_host_string(host_string):
    """
    >>> _parse_host_string('example.com')
    (None, 'example.com', None)
    >>> _parse_host_string('user@example.com')
    ('user', 'example.com', None)
    >>> _parse_host_string('example.com:8080')
    (None, 'example.com', '8080')
    >>> _parse_host_string('user@example.com:8080')
    ('user', 'example.com', '8080')
    """

    m = re.search(r'^(?P<user>\w+)@(?P<rest>.*)$', host_string)
    if m:
        user = m.group('user')
        host_string = m.group('rest')
    else:
        user = None

    m = re.search(r'^(?P<host>.*):(?P<port>\d+)$', host_string)
    if m:
        port = m.group('port')
        host_string = m.group('host')
    else:
        port = None

    return (user, host_string, port)

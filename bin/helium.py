#!/usr/bin/env python3
import sys
import os
import time
import json
import argparse
import subprocess
import requests
import six

# defaults
CHRONOS_URL = ''
IRODS_HOST = 'https://auth.commonsshare.org'
IRODS_PORT = '1247'
IRODS_ZONE = 'commonssharetestZone'
IRODS_CWD = '/'+IRODS_ZONE
IRODS_HOME = '/{}/home/{}'

def main(argv):
    parser = argparse.ArgumentParser(description="Helpful launcher script for Helium Data Commons containers")
    
    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')
    # subcommand build
    build_parser = subparsers.add_parser('build', help='Build an image')
    build_parser.add_argument('image', type=str, choices=['all','base','jupyter'])
    
    # subcommand run
    run_parser = subparsers.add_parser('run', help='Run an image')
    run_subparsers = run_parser.add_subparsers(title='run-subcommands', dest='image')

    # subcommand login
    login_parser = subparsers.add_parser('login', help='Authenticate to the Helium stack')

    # options specific to the base image
    base_parser = run_subparsers.add_parser('base', help='run the datacommons-base image')
    entry_group = base_parser.add_mutually_exclusive_group(required=True)
    entry_group.add_argument('--cwl', action='store_true',
            help='Enters the cwltool virtualenvironment')
    entry_group.add_argument('--toil', action='store_true',
            help='Enters the toil virtual environment')

    # options specific to the jupyter image
    jupyter_parser = run_subparsers.add_parser('jupyter', help='run the datacommons-jupyter image')
    jupyter_entry_group = jupyter_parser.add_mutually_exclusive_group(required=True)
    jupyter_entry_group.add_argument('--wes-server', action='store_true', help='attach to the WES server process')
    jupyter_entry_group.add_argument('--jupyter', action='store_true', help='attach to the Jupyter notebook process')
    jupyter_entry_group.add_argument('--venv', action='store_true', help='enter Jupyter virtual environment')

    # general run parser args
    def add_general_run_args(parser):
        parser.add_argument('-U', '--username', dest='username', required=True, help='Username to connect to iRODS.')
        creds_group = parser.add_mutually_exclusive_group(required=True)
        creds_group.add_argument('-P', '--password', type=str, default=None, help='Password to authenticate with.')
        creds_group.add_argument('-T', '--access-token', type=str, default=None, help='Access token to authenticate with.')
        creds_group.add_argument('-K', '--user-key', type=str, default=None, help='User key to authenticate with.')
    
        parser.add_argument('--irods-host', type=str, default=IRODS_HOST, help='iRODS host to connect to.')
        parser.add_argument('--irods-port', type=str, default=IRODS_PORT, help='iRODS port to connect to.')
        parser.add_argument('--irods-zone', type=str, default=IRODS_ZONE, help='iRODS zone to connect to.')
        parser.add_argument('--irods-home', type=str, default=None, help='iRODS home to use.')
        parser.add_argument('--irods-cwd', type=str, default=IRODS_CWD, help='iRODS collection to mount.')
        parser.add_argument('--chronos-url', type=str, default=CHRONOS_URL, help='Chronos instance to send jobs to.')
        parser.add_argument('--openid-provider', type=str, help='When using access token, specify provider, otherwise uses default provider')
    add_general_run_args(base_parser)
    add_general_run_args(jupyter_parser)

    options = parser.parse_args(argv)

    #print(str(options))
    # couldn't find a good way to automatically require subcommands, check for them here
    if options.subcommand is None:
        parser.print_help()
        exit(1)
    elif options.subcommand == 'build':
        if options.image is None:
            build_parser.print_help()
            exit(1)
        build(options)
    elif options.subcommand == 'run':
        # post process IRODS_HOME if not provided
        if options.irods_home is None:
            options.irods_home = IRODS_HOME.format(options.irods_zone, options.username)
        if options.image is None:
            run_parser.print_help()
            exit(1)
        run(options)
    elif options.subcommand == 'login':
        login()
    else:
        raise RuntimeError('Unrecognized subcommand')

def build(options):
    os.chdir('docker')
    imagename = options.image
    build_args = ['/bin/bash', 'build-{}.sh'.format(imagename)]
    proc = subprocess.Popen(build_args, stdout=subprocess.PIPE, universal_newlines=True)
    for line in proc.stdout:
        print(line, end='')
    ret = proc.wait()
    print('build({}) returned status_code: {}'.format(imagename, ret))

def run(options):
    env = {}
    if options.chronos_url: env['CHRONOS_URL'] = options.chronos_url
    if options.irods_host: env['IRODS_HOST'] = options.irods_host
    if options.irods_port: env['IRODS_PORT'] = options.irods_port
    if options.irods_zone: env['IRODS_ZONE_NAME'] = options.irods_zone
    if options.irods_home: env['IRODS_HOME'] = options.irods_home
    if options.irods_cwd: env['IRODS_CWD'] = options.irods_cwd
    if options.username: env['IRODS_USER_NAME'] = options.username
    if options.password: env['IRODS_PASSWORD'] = options.password
    if options.access_token:
        env['IRODS_AUTHENTICATION_SCHEME'] = 'openid'
        env['IRODS_ACCESS_TOKEN'] = options.access_token
        if 'IRODS_PASSWORD' in env: del(env['IRODS_PASSWORD'])
    if options.user_key:
        env['IRODS_AUTHENTICATION_SCHEME'] = 'openid'
        env['IRODS_USER_KEY'] = options.user_key
        if 'IRODS_PASSWORD' in env: del(env['IRODS_PASSWORD'])
    # turns a dictionary of env var to val into a list of [ '-e', 'k=v', '-e', 'k2=v2', ... ]
    env_args = [val for tuple in zip(['-e' for k in env], ["{}={}".format(k,v) for k,v in env.items() if env[k]]) for val in tuple]
    
    run_args = [
        'docker', 'run', '-it', '--privileged', '--rm',
        '--name', 'dc_{}'.format(options.image), '-p', '90:80'] \
        + env_args \
        + ['heliumdatacommons/datacommons-{}'.format(options.image)]
    if options.image == 'base':
        if options.toil:
            run_args.append('toilvenv')
        elif options.cwl:
            run_args.append('venv')
    elif options.image == 'jupyter':
        if options.wes_server:
            run_args.append('wes-server')
        elif options.jupyter:
            run_args.append('jupyter')
        elif options.venv:
            run_args.append('venv')
    else:
        raise RuntimeError('Unknown image: {}'.format(options.image))
    print('COMMAND STRING: \n{}'.format(' '.join(run_args)))
    proc = subprocess.Popen(run_args, universal_newlines=True)
    #for line in proc.stdout:
    #    print(line)
    ret = proc.wait()
    print('run({}) returned status_code: {}'.format(options.image, ret))


def login():
    base_url = 'https://auth.commonsshare.org'
    resp1 = requests.get(base_url + '/authorize?provider=globus&scope=openid%20email%20profile')
    if resp1.status_code != 200:
        raise RuntimeError('Failed to acquire login url')
    else:
        body = json.loads(resp1.content.decode('utf-8'))
        if 'authorization_url' not in body or 'nonce' not in body:
            raise RuntimeError('Improperly formatted response on initialization')
        print('Please log in with following URL:\n{}\n'.format(body['authorization_url']))

        max_wait = 120
        interval = 3
        token_url = base_url + '/token?nonce=' + body['nonce']
        success = False
        for i in range(int(max_wait/interval)):
            resp2 = requests.get(token_url)
            if resp2.status_code == 200:
                body = json.loads(resp2.content.decode('utf-8'))
                if 'access_token' not in body or 'user_name' not in body:
                    raise RuntimeError('Improperly formatted response on token retrieval')
                print('Detected login for user: {}'.format(body['user_name']))
                inp = ''
                while inp.lower() not in ['y', 'n']:
                    inp = six.moves.input('Is this the correct identity you wish to use? (y/n) ')
                if inp == 'n':
                    print('Please log out of the Helium and Globus in your '
                        + 'browser and re-run this script to log in with a different account.')
                    return
                print('Access Token:')
                print(body['access_token'])
                success = True
                break
            time.sleep(interval)
        if not success:
            print('Failed to login within timeout window of {} seconds' + str(max_wait))

if __name__ == "__main__":
    main(sys.argv[1:])

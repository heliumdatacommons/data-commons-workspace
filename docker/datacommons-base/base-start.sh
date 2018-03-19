#!/bin/bash

cd ~/
. ~/.profile

bash /home/dockeruser/entrypoint.sh

# For Toil
sudo mkdir -p /var/log/datacommons
sudo chown -R dockeruser:datacommons /var/log/datacommons
toillog=/var/log/datacommons/toillog
touch ${toillog}

# Determine which virtual env to start at run time
if [ "$1" == "venv" ] || [ -z "$1" ]; then
    # interactive
    cd ~/venv && source bin/activate
    bash -i
elif [ "$1" == "toilvenv" ]; then
    toilvenv
elif [ "$1" == "_toil_worker" ]; then
    /usr/bin/_toil_worker "${@:2}"
elif [ "$1" == "_cwl_worker" ]; then
    # run commands in virtualenvironment
    cd ~/venv && source bin/activate
    bash -c "$@"
fi

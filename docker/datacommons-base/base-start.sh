#!/bin/bash

cd ~/
. ~/.profile

bash /home/dockeruser/entrypoint.sh

# For Toil
sudo mkdir -p /var/log/datacommons
sudo chown -R dockeruser:datacommons /var/log/datacommons
toillog=/var/log/datacommons/toillog
touch ${toillog}

echo "base-start: [$@]"
env
# Determine which virtual env to start at run time
if [ "$1" == "venv" ] || [ -z "$1" ]; then
    # interactive
    cd ~/venv && source bin/activate
    bash -i
elif [ "$1" == "toilvenv" ]; then
    toilvenv
elif [ "$1" == "_toil_worker" ]; then
    echo "running [_toil_worker ${@:2}"
    cd /opt/toil/ && source venv2.7/bin/activate
    _toil_worker ${@:2}
    #/usr/bin/_toil_worker "${@:2}"
elif [ "$1" == "_cwl_worker" ]; then
    echo "running _cwl_worker [${@:2}]"
    # run commands in virtualenvironment
    cd ~/venv && source bin/activate
    bash -c "${@:2}"
    ls /renci/irods/home/kferriter
    ils home/kferriter
elif [ "$1" == "_toil_exec" ]; then
    echo "running _toil_exec"
    toilvenv "${@:2}"
elif [ "$1" == "_cwl_exec" ]; then
    echo "running _cwl_exec"
    venv "${@:2}"
elif [ "$1" == "sshd" ]; then
    #if [ ! -z "$SSH_PUBKEY" ]; then
        echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
    #fi
    sudo /usr/sbin/sshd -D
fi
echo "CALLING SYNC"
#sync -f /renci/irods
ls /renci/irods/home/kferriter
ils home/kferriter
sudo umount.davfs /renci/irods/
#bash -i
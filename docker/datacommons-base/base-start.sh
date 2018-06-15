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

if [ ! -z "$SSH_PUBKEY" ]; then
    echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
fi

# start dockerd
sudo /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --default-runtime=docker-runc  --userland-proxy-path=/usr/libexec/docker/docker-proxy-current --log-driver=json-file 2>&1 > /tmp/dockerd.log &
#sudo /usr/bin/dockerd 2>&1 > /dev/null &

# Determine which virtual env to start at run time
if [ "$1" == "sshd" ]; then
sudo /usr/sbin/sshd -D
else
sudo /usr/sbin/sshd
if [ "$1" == "venv" ] || [ -z "$1" ]; then
    # interactive
    cd ~/venv && source bin/activate
    bash -i
elif [ "$1" == "toilvenv" ]; then
    toilvenv
elif [ "$1" == "_toil_worker" ]; then
    echo "running _toil_worker [${@:2}]"
    cd /opt/toil/ && source venv2.7/bin/activate
    _toil_worker ${@:2}
    #/usr/bin/_toil_worker "${@:2}"
elif [ "$1" == "_cwl_worker" ]; then
    echo "running _cwl_worker [${@:2}]"
    # run commands in virtualenvironment
    cd ~/venv && source bin/activate
    bash -c "${@:2}"
elif [ "$1" == "_toil_exec" ]; then
    echo "running _toil_exec"
    toilvenv "${@:2}"
elif [ "$1" == "_cwl_exec" ]; then
    echo "running _cwl_exec"
    venv "${@:2}"
fi
fi
#echo "CALLING SYNC"
#sync -f /renci/irods
#sudo umount.davfs /renci/irods/
#bash -i
#!/bin/bash

cd ~/
bash /home/dockeruser/entrypoint.sh
. ~/.profile # pull any updated values set in entrypoint.sh

#if [ -d /toil-intermediate ]; then
    #sudo chown -R dockeruser:datacommons /toil-intermediate
#fi

# For logs
timestamp=$(date +%H:%m:%ST%Y-%M-%d%z)
DAVRODS_CWD="/${IRODS_ZONE_NAME}"
logdir="${IRODS_MOUNT}${IRODS_HOME#$DAVRODS_CWD}/.log" # irods home path minus the cwd, if they overlap, appended to the irods mountpoint
echo "logdir: $logdir"
mkdir -p $logdir
toilworkerlog=${logdir}/toil_worker_${timestamp}
toilexeclog=${logdir}/toil_exec_${timestamp}
cwlworkerlog=${logdir}/cwl_worker_${timestamp}
cwlexeclog=${logdir}/cwl_exec_${timestamp}

echo "base-start: [$@]"
env #TODO remove

if [ ! -z "$SSH_PUBKEY" ]; then
    echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
fi

# start dockerd
sudo /usr/bin/dockerd-current \
    --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current \
    --default-runtime=docker-runc > /tmp/dockerd.log 2>&1 &

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
        touch $toilworkerlog
        _toil_worker ${@:2} 2>&1 | tee $toilworkerlog
        #/usr/bin/_toil_worker "${@:2}"
    elif [ "$1" == "_cwl_worker" ]; then
        echo "running _cwl_worker [${@:2}]"
        # run commands in virtualenvironment
        cd ~/venv && source bin/activate
        touch $cwlworkerlog
        bash -c "${@:2}" 2>&1 | tee $cwlworkerlog
    elif [ "$1" == "_toil_exec" ]; then
        echo "running _toil_exec"
        touch $toilexeclog
        toilvenv "${@:2}" 2>&1 | tee $toilexeclog
    elif [ "$1" == "_cwl_exec" ]; then
        echo "running _cwl_exec"
        touch $cwlexeclog
        venv "${@:2}" 2>&1 | tee $cwlexeclog
    fi
fi
echo "calling sync"
sync
sudo umount.davfs ${IRODS_MOUNT}
echo "finished sync"
#fusermount -u ${IRODS_MOUNT}
#bash -i
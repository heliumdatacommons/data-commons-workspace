#!/bin/bash

cd ~/
bash /home/dockeruser/entrypoint.sh
. ~/.profile # pull any updated values set in entrypoint.sh

#if [ -d /toil-intermediate ]; then
    #sudo chown -R dockeruser:datacommons /toil-intermediate
#fi

# For logs
log_suffix=$(date +%Y-%m-%dT%H:%M:%S%Z)
if [ ! -z "$WORKFLOW_NAME" ]; then
    log_suffix="${WORKFLOW_NAME}.${log_suffix}"
fi
DAVRODS_CWD="/${IRODS_ZONE_NAME}"
logdir="${IRODS_MOUNT}${IRODS_HOME#$DAVRODS_CWD}/.log" # irods home path minus the cwd, if they overlap, appended to the irods mountpoint
echo "logdir: $logdir"
if [ ! -d $logdir ]; then
    mkdir -p $logdir
fi
toilworkerlog=${logdir}/toil_worker_${log_suffix}
toilexeclog=${logdir}/toil_exec_${log_suffix}
cwlworkerlog=${logdir}/cwl_worker_${log_suffix}
cwlexeclog=${logdir}/cwl_exec_${log_suffix}

echo "base-start: [$@]"

if [ ! -z "$SSH_PUBKEY" ]; then
    echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
fi

# start dockerd
#sudo /usr/bin/dockerd-current \
#    --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current \
#    --default-runtime=docker-runc > /tmp/dockerd.log 2>&1 &

#TODO look into the warnings from this, but they do not currently impact docker
sudo /usr/bin/dockerd > /tmp/dockerd.log 2>&1 &

# Determine which virtual env to start at run time
exitcode=0
sudo mkdir -p /var/run/sshd
if [ "$1" == "sshd" ]; then
    sudo /usr/sbin/sshd -D
else
    sudo /usr/sbin/sshd
    if [ "$1" == "venv" ] || [ -z "$1" ]; then
        # interactive
        cd ~/venv && source bin/activate
        bash -i
    elif [ "$1" == "toilvenv" ]; then
        cd /opt/toil && source venv2.7/bin/activate
        if [[ -z "$2" ]]; then
            bash -i
        else
            # automated command inside the toil env
            echo "running toilvenv automated '${@:2}'"
            bash -c "${@:2}"
            exitcode=$?
        fi
        #toilvenv
    elif [ "$1" == "_toil_worker" ]; then
        echo "running _toil_worker [${@:2}]"
        cd /opt/toil/ && source venv2.7/bin/activate
        touch $toilworkerlog
        _toil_worker ${@:2} 2>&1 | tee $toilworkerlog
        exitcode=${PIPESTATUS[0]}
        #/usr/bin/_toil_worker "${@:2}"
    elif [ "$1" == "_cwl_worker" ]; then
        echo "running _cwl_worker [${@:2}]"
        # run commands in virtualenvironment
        cd ~/venv && source bin/activate
        touch $cwlworkerlog
        bash -c "${@:2}" 2>&1 | tee $cwlworkerlog
        exitcode=${PIPESTATUS[0]}
    elif [ "$1" == "_toil_exec" ]; then
        echo "running _toil_exec"
        touch $toilexeclog
        toilvenv "${@:2}" 2>&1 | tee $toilexeclog
        exitcode=${PIPESTATUS[0]}
    elif [ "$1" == "_cwl_exec" ]; then
        echo "running _cwl_exec"
        touch $cwlexeclog
        venv "${@:2}" 2>&1 | tee $cwlexeclog
        exitcode=${PIPESTATUS[0]}
    fi
fi
echo "calling sync"
#sync
sudo umount -f ${IRODS_MOUNT}
echo "finished sync"
#fusermount -u ${IRODS_MOUNT}

# auto-delete self if it seems part of an appliance
#if [ "$1" == "_toil_exec" ] && [ ! -z "${PIVOT_URL}" ] && [ ! -z "${WORKFLOW_NAME}" ]; then
#    curl -X DELETE "${PIVOT_URL}/${WORKFLOW_NAME}"
#fi

exit ${exitcode}
#!/bin/bash

# fixes issue in docker for mac where fuse permissions are restricted to root:root
# https://github.com/theferrit32/data-commons-workspace/issues/5
if [ -c /dev/fuse ]; then sudo chmod 666 /dev/fuse; fi


cd ~/
. ~/.profile

if [ ! -f ~/.irods/.irodsA ]; then
    # irods not initialized
    echo "iRODS not initialized"

    if [ ! -z "$IRODS_PASSWORD" ]; then
        echo "Authenticating to iRODS using provided password"
        echo "$IRODS_PASSWORD" | iinit -e
    else
        echo "Authenticating to iRODS using standard input"
        iinit
    fi
fi

if ! mount | grep "irodsFs.*/irods"; then
    echo "Mounting iRODS"
    irodsFs -onocache -o allow_other /renci/irods
fi

# for Davrods
sudo /usr/sbin/httpd &

if [ "$1" == "venv" ] || [ -z "$1" ]; then
    # interactive
    cd ~/venv && source bin/activate
    bash -i
else
    # run commands in virtualenvironment
    cd ~/venv && source bin/activate
    bash -c "$@"
fi

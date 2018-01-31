#!/bin/bash

# fixes issue in docker for mac where fuse permissions are restricted to root:root
# https://github.com/theferrit32/data-commons-workspace/issues/5
if [ -f /dev/fuse ]; then sudo chmod 666 /dev/fuse; fi


cd ~/
. ~/.profile

if [ ! -f ~/.irods/.irodsA ]; then
    # irods not initialized

    if [ ! -z "$IRODS_PASSWORD" ]; then
        echo "$IRODS_PASSWORD" | iinit -e
    else
        iinit
    fi
fi

if ! mount | grep "irodsFs.*/irods"; then
    irodsFs -onocache -o allow_other /renci/irods
fi


sudo /usr/sbin/httpd &

exec $@

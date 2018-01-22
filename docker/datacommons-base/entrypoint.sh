#!/bin/bash
cd ~/
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

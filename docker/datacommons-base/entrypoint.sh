#!/bin/bash
cd ~/
if [ ! -f ~/.irods/.irodsA ]; then
    # irods not initialized
    iinit
fi

if ! mount | grep "irodsFs.*/irods"; then
    irodsFs -onocache -o allow_other /renci/irods
fi

sudo /usr/sbin/httpd &

exec $@

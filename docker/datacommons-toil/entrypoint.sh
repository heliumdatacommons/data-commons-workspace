#!/bin/bash
cd ~/
. ~/.bashrc
echo "in entrypont.sh"

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

# start apache for webdav (port 80)
sudo /usr/sbin/httpd &

sudo mkdir -p /var/log/datacommons
sudo chown -R dockeruser:datacommons /var/log/datacommons

# allow specification of a few specific run commands. For others, pass off to exec
# when a process is backgrounded, write to its log file
if [ "$1" == "toilvenv" ] || [ -z "$1" ]; then
    toilvenv
elif [ "$1" == "_toil_worker" ]; then
    /usr/bin/_toil_worker "${@:2}"
else
    echo "Calling toilvenv"
    toilvenv "$@"
fi

# drop back to venv shell when other commands are terminated or backgrounded
#/bin/bash -i

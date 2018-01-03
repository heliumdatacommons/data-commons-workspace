#!/bin/bash
cd ~/
#source ~/.bashrc


if [ ! -f ~/.irods/.irodsA ]; then
    # irods not initialized
    iinit
fi

if ! mount | grep "irodsFs.*/irods"; then
    irodsFs -onocache -o allow_other /renci/irods
fi

# start apache for webdav (port 80)
sudo /usr/sbin/httpd &

sudo mkdir -p /var/log/datacommons
sudo chown -R dockeruser:datacommons /var/log/datacommons

# allow specification of a few specific run commands. Ignore others
# when a process is backgrounded, write to its log file
if [ "$1" == "toilvenv" ] || [ -z "$1" ]; then
    toilvenv
fi

# drop back to venv shell when other commands are terminated or backgrounded
#/bin/bash -i

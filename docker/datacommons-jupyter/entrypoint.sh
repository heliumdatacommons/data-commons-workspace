#!/bin/bash

# fixes issue in docker for mac where fuse permissions are restricted to root:root
# https://github.com/theferrit32/data-commons-workspace/issues/5
if [ -c /dev/fuse ]; then sudo chmod 666 /dev/fuse; fi

cd ~/
. ~/.profile
#source ~/.bashrc

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

cd ~/venv
source bin/activate

weslog=/var/log/datacommons/weslog
jupyterlog=/var/log/datacommons/jupyterlog
sudo mkdir -p /var/log/datacommons
sudo chown -R dockeruser:datacommons /var/log/datacommons
touch ${weslog}
touch ${jupyterlog}

# allow specification of a few specific run commands. Ignore others
# when a process is backgrounded, write to its log file
if [ "$1" == "jupyter" ] || [ -z "$1" ]; then
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons >> ${weslog} 2>&1  &
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token=''
elif [ "$1" == "wes-server" ]; then
    # suppress jupyter output
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='' >> ${jupyterlog} 2>&1 &
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons
elif [ "$1" == "venv" ]; then
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='' >> ${jupyterlog} 2>&1 &
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons >> ${weslog} 2>&1 &
    #deactivate && venv
    bash -i
fi

# drop back to venv shell when other commands are terminated or backgrounded
#/bin/bash -i

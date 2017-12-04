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

cd ~/venv
source bin/activate


# allow specification of a few specific run commands. Ignore others
if [ "$1" == "jupyter" ] || [ -z "$1" ]; then
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons > /dev/null 2>&1 &
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token=''
elif [ "$1" == "wes-server" ]; then
    # suppress jupyter output
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='' > /dev/null 2>&1 &
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons
elif [ "$1" == "venv" ]; then
    jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='' > /dev/null 2>&1 &
    wes-server --backend=wes_service.cwl_runner --opt runner=cwltool --opt extra=--data-commons > /dev/null 2>&1 &
    deactivate && venv
fi

# drop back to venv shell when other commands are terminated or backgrounded
#/bin/bash -i

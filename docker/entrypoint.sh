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

jupyter notebook --ip=0.0.0.0 --no-browser

# uncomment to drop back to bash if jupyter notebook is terminated
#/bin/bash -i

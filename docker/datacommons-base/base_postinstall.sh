#!/bin/bash
user="dockeruser"
group="datacommons"

set -e

if [ ! -d ~/.irods ]; then mkdir ~/.irods; fi

# set global httpd ServerName to localhost
sudo sed -i 's|.*ServerName.*|ServerName localhost|g' /etc/apache2/apache2.conf

# set user/group for davfs
sudo sed -i 's|^# dav_user.*|dav_user davfs2|g' /etc/davfs2/davfs2.conf
sudo sed -i 's|^# dav_group.*|dav_group davfs2|g' /etc/davfs2/davfs2.conf

# TODO add httpd Alias for datacommons log
# https://httpd.apache.org/docs/2.4/urlmapping.html

# run iinit
if [ -z "$IRODS_PASSWORD" ]; then
    echo "Docker image will not contain an auto-mounted irods filesystem"
    echo "When it is first run in a new container, it will perform authentication"
    echo "To authenticate at build time, pass '--build-arg IRODS_PASSWORD=<your_password>' to docker build"
else
    iinit "$IRODS_PASSWORD"
    echo
fi

IRODS_MOUNT="/renci/irods"
if [ ! -d $IRODS_MOUNT ]; then
    sudo mkdir -p $IRODS_MOUNT
    sudo chown "${user}:${group}" $IRODS_MOUNT
fi


# if bashrc has IRODS_MOUNT set, reset it to current one, else add it
if grep IRODS_MOUNT ~/.profile; then
    sed -i "s|^export IRODS_MOUNT=.*$|export IRODS_MOUNT=${IRODS_MOUNT}|g" ~/.profile
else
    echo "export IRODS_MOUNT=${IRODS_MOUNT}" >> ~/.profile
fi

# set up python 3 virtualenv for everything else
export VENV=~/venv
python3.6 -m venv $VENV
cd $VENV
source bin/activate
pip install stars
# install cwltool fork
git clone https://github.com/stevencox/cwltool.git
cd cwltool && pip install .; cd $VENV

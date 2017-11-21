#!/bin/bash
# run as regular user that has sudo access
# this attempts to be as idempotent as possible

user="dockeruser"
group="datacommons"

set -e
sudo yum update -y

# install additional repos
sudo yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm

# install misc packages
sudo yum install -y python36u python36u-devel fuse gcc git vim

# install irods-icommands if not already installed
if ! yum list installed irods-icommands > /dev/null 2>&1; then
    curl -O ftp://ftp.renci.org/pub/irods/releases/4.1.11/centos7/irods-icommands-4.1.11-centos7-x86_64.rpm
    sudo yum localinstall -y irods-icommands-4.1.11-centos7-x86_64.rpm
fi

if [ ! -d ~/.irods ]; then mkdir ~/.irods; fi
echo '{
    "irods_port": 1247,
    "irods_host": "stars-dw1.edc.renci.org",
    "irods_user_name": "rods",
    "irods_zone_name": "tempZone"
}' > ~/.irods/irods_environment.json

# run iinit in tty mode so we can send password on stdin
#TODO possibly use ansible variable substitution here
if [ -z "$IRODS_PASSWORD" ]; then
    echo "Docker image will not contain an auto-mounted irods filesystem"
    echo "When it is first run in a new container, it will perform authentication"
    echo "To authenticate at build time, pass '--build-arg IRODS_PASSWORD=\"<your_password>\"' to docker build"
else
    echo "$IRODS_PASSWORD" | iinit -e
    echo
fi

IRODS_MOUNT="/renci/irods"
if [ ! -d $IRODS_MOUNT ]; then
    sudo mkdir -p $IRODS_MOUNT
    sudo chown "${user}:${group}" $IRODS_MOUNT
fi


# allow fuse cross-user access so docker as root can see irods
sudo sed -i 's/^#.*user_allow_other/user_allow_other/g' /etc/fuse.conf

# if bashrc has IRODS_MOUNT set, reset it to current one, else add it
if grep IRODS_MOUNT ~/.bashrc; then
    sed -i "s|^export IRODS_MOUNT=.*$|export IRODS_MOUNT=${IRODS_MOUNT}|g" ~/.bashrc
else
    echo "export IRODS_MOUNT=${IRODS_MOUNT}" >> ~/.bashrc
fi

# set up python virtualenv
export VENV=~/venv
python3.6 -m venv $VENV
cd $VENV
source bin/activate
# PyPI stars is out of date
#pip install stars
git clone https://github.com/stevencox/stars.git
cd stars/cluster/src && pip install . && cd $VENV

git clone https://github.com/stevencox/cwltool.git
cd cwltool && pip install . && cd $VENV
pip install jupyter

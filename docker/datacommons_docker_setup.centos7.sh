#!/bin/bash
# run as regular user that has sudo access
# this attempts to be as idempotent as possible

# NOTE: this is deprecated and no longer maintained

user="dockeruser"
group="datacommons"

set -e
sudo yum update -y

# install additional repos
sudo yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm

# install misc packages
sudo yum install -y python36u python36u-devel fuse gcc git vim nodejs

# install irods-icommands if not already installed
if ! rpm -qa | grep "irods-icommands" &> /dev/null; then
    #curl -O ftp://ftp.renci.org/pub/irods/releases/4.1.11/centos7/irods-icommands-4.1.11-centos7-x86_64.rpm
    #sudo yum localinstall -y irods-icommands-4.1.11-centos7-x86_64.rpm

    # install v4.2.1, which is required by Davrods v4.2.1_1.2.0
    sudo yum install -y irods-icommands-4.2.1-1.x86_64
fi

# install davrods if not installed
if ! rpm -qa | grep davrods &> /dev/null; then
    curl -O https://github.com/UtrechtUniversity/davrods/releases/download/4.2.1_1.2.0/davrods-4.2.1_1.2.0-1.rpm
    sudo yum install -y davrods-4.2.1_1.2.0-1.rpm
fi

if [ ! -d ~/.irods ]; then mkdir ~/.irods; fi
irods_environment='{
    "irods_port": 1247,
    "irods_host": "stars-fuse.renci.org",
    "irods_user_name": "rods",
    "irods_zone_name": "tempZone"
}'
echo irods_environment > ~/.irods/irods_environment.json
echo irods_environment | sudo tee /etc/httpd/irods/irods_environment.json

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
if grep IRODS_MOUNT ~/.profile; then
    sed -i "s|^export IRODS_MOUNT=.*$|export IRODS_MOUNT=${IRODS_MOUNT}|g" ~/.profile
else
    echo "export IRODS_MOUNT=${IRODS_MOUNT}" >> ~/.profile
fi
echo "export WES_API_HOST=localhost:8080" >> ~/.profile
echo "export WES_API_PROTO=http" >> ~/.profile


# set up python 3 virtualenv for everything else
export VENV=~/venv
python3.6 -m venv $VENV
cd $VENV
source bin/activate
pip install stars
# install cwltool fork
git clone https://github.com/stevencox/cwltool.git
cd cwltool && pip install .; cd $VENV
pip install jupyter

# installing wes-service fork in python3 env
git clone https://github.com/stevencox/workflow-service.git
cd workflow-service && pip install .; cd $VENV


sudo yum install -y krb5-devel
pip install sparkmagic
set -x
jupyter nbextension enable --py --sys-prefix widgetsnbextension
sparkmagic_path=$(pip show sparkmagic | grep -i location | sed -e "s,.*: ,,")
cd $sparkmagic_path
jupyter-kernelspec install sparkmagic/kernels/sparkkernel --user
jupyter-kernelspec install sparkmagic/kernels/pysparkkernel --user
jupyter-kernelspec install sparkmagic/kernels/pyspark3kernel --user
jupyter-kernelspec install sparkmagic/kernels/sparkrkernel --user
mkdir /home/dockeruser/.sparkmagic
cp /home/dockeruser/sparkmagic.config.json /home/dockeruser/.sparkmagic/config.json

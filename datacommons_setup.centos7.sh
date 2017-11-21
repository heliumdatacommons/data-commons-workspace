# run as evryscope user
# this attempts to be as idempotent as possible

set -e
sudo yum update -y

# install additional repos
sudo yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm

# install misc packages
sudo yum install -y python36u python36u-devel docker

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

# allow fuse cross-user access so docker as root can see irods
sudo sed -i 's/^#.*user_allow_other/user_allow_other/g' /etc/fuse.conf

IRODS_MOUNT="/renci/irods"
if [ ! -d "$IRODS_MOUNT" ]; then
    sudo mkdir -p "$IRODS_MOUNT"
    sudo chown "evryscope:service accounts" "$IRODS_MOUNT"
fi

#TODO possibly use ansible variable substitution here
if [ -z "$IRODS_PASSWORD" ]; then
    echo "irods filesystem will not be authenticated automatically"
    echo "Set password with 'export IRODS_PASSWORD=\"<your-password>\"'"
else
    # run iinit in tty mode so we can send password on stdin
    echo "$IRODS_PASSWORD" | iinit -e
    echo

    # if not mounted, mount
    if ! mount | grep "irodsFs.*${IRODS_MOUNT}"; then
        irodsFs -onocache -o allow_other $IRODS_MOUNT
    fi
fi


# if bashrc has IRODS_MOUNT set, reset it to current one, else add it
if grep IRODS_MOUNT ~/.bashrc; then
    sed -i "s|^export IRODS_MOUNT=.*$|export IRODS_MOUNT=${IRODS_MOUNT}|g" ~/.bashrc
else
    echo "export IRODS_MOUNT=${IRODS_MOUNT}" >> ~/.bashrc
fi

# set up python virtualenv
python3.6 -m venv ~/venv
cd ~/venv
source bin/activate
pip install stars
git clone https://github.com/stevencox/cwltool.git
cd cwltool && pip install . && cd ..
pip install jupyter

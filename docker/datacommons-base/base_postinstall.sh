user="dockeruser"
group="datacommons"

set -e

if [ ! -d ~/.irods ]; then mkdir ~/.irods; fi
irods_environment='{
    "irods_port": 1247,
    "irods_host": "stars-fuse.renci.org",
    "irods_user_name": "rods",
    "irods_zone_name": "tempZone"
}'
echo $irods_environment > ~/.irods/irods_environment.json
echo $irods_environment | sudo tee /etc/httpd/irods/irods_environment.json

# set global httpd ServerName to localhost
sudo sed -i 's|.*ServerName.*|ServerName localhost|g' /etc/httpd/conf/httpd.conf

# TODO add httpd Alias for datacommons log
# https://httpd.apache.org/docs/2.4/urlmapping.html


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

# set up python 3 virtualenv for everything else
export VENV=~/venv
python3.6 -m venv $VENV
cd $VENV
source bin/activate
pip install stars
# install cwltool fork
git clone https://github.com/stevencox/cwltool.git
cd cwltool && pip install .; cd $VENV

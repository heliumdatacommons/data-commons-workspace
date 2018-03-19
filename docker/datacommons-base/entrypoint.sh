#!/bin/bash

# fixes issue in docker for mac where fuse permissions are restricted to root:root
# https://github.com/theferrit32/data-commons-workspace/issues/5
if [ -c /dev/fuse ]; then sudo chmod 666 /dev/fuse; fi


cd ~/
. ~/.profile

# Write iRODS enviornment configuration to files
if [ ! -z "$IRODS_PORT" ] && \
    [ ! -z "$IRODS_HOST" ] && \
    [ ! -z "$IRODS_USER_NAME" ] && \
    [ ! -z "$IRODS_ZONE_NAME" ]
then
    irods_environment='{
        "irods_port": "'${IRODS_PORT}'",
        "irods_host": "'${IRODS_HOST}'",
        "irods_user_name": "'${IRODS_USER_NAME}'",
        "irods_zone_name": "'${IRODS_ZONE_NAME}'"'

    if [ ! -z "$IRODS_HOME" ]; then
        irods_environment=${irods_environment}', "irods_home": "'${IRODS_HOME}'"'
    fi
    if [ ! -z "$IRODS_CWD" ]; then
        irods_environment=${irods_environment}', "irods_cwd": "'${IRODS_CWD}'"'
    fi

    irods_environment=${irods_environment}' }'
    echo $irods_environment > ~/.irods/irods_environment.json
    echo $irods_environment | sudo tee /etc/httpd/irods/irods_environment.json
fi

# Replace values in Davrods config file
if [ ! -z "$IRODS_PORT" ] && \
    [ ! -z "$IRODS_HOST" ] && \
    [ ! -z "$IRODS_ZONE_NAME" ]
then
    declare -A irods_config
    irods_config=(
        [%%IRODS_PORT%%]=${IRODS_PORT}
        [%%IRODS_HOST%%]=${IRODS_HOST}
        [%%IRODS_ZONE_NAME%%]=${IRODS_ZONE_NAME}
    )

    configurer() {
        # Loop the config array
        for i in "${!irods_config[@]}"
        do
            search=$i
            replace=${irods_config[$i]}
            # Note the "" after -i, needed in OS X
            sudo sed -i "s/${search}/${replace}/g" /etc/httpd/conf.d/davrods-vhost.conf
        done
    }
    configurer
fi

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

#!/bin/bash

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

# Decide on DAVRODS_ROOT value
# if [ ! -z "$IRODS_CWD" ]
# then
#     DAVRODS_ROOT=$IRODS_CWD
# else
#     DAVRODS_ROOT='Zone'
# fi

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
        # [%%DAVRODS_ROOT%%]=${DAVRODS_ROOT}
        [%%DAVRODS_ROOT%%]='Zone'
    )

    configurer() {
        # Loop the config array
        for i in "${!irods_config[@]}"
        do
            search=$i
            replace=${irods_config[$i]}
            if [[ $replace == /* ]]; then replace='\'$replace; fi
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
        iinit "$IRODS_PASSWORD"
    else
        echo "Authenticating to iRODS using standard input"
        iinit
    fi
fi

# start apache for webdav (port 80)
sudo /usr/sbin/httpd &

# avoid davfs2 retries and possible failure by waiting for httpd to start first
wait_limit=30 # max seconds to wait
x=0
echo -n "waiting for httpd to start"
while ! curl localhost:80 >/dev/null 2>&1 && [ $x -lt $wait_limit ]; do
    x=$((x+1))
    echo -n "."
    sleep 1
done; echo
if [ $x -eq $wait_limit ]; then
    echo "httpd did not start in under $wait_limit seconds"
fi

# mount the webdav port to the filesystem
echo "http://localhost:80 ${IRODS_USER_NAME} ${IRODS_PASSWORD}" | sudo tee -a /etc/davfs2/secrets >> /dev/null
sudo mount -t davfs -o uid=dockeruser,gid=datacommons "http://localhost:80" ${IRODS_MOUNT}

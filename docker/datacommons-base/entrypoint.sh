#!/bin/bash

cd ~/
. ~/.profile
printf "ENTRYPOINT\n\n"
env

# make env vars persistent
declare -a env_vars=("IRODS_PORT" "IRODS_HOST" "IRODS_HOME" "IRODS_USER_NAME" "IRODS_PASSWORD" "IRODS_ZONE_NAME" "CHRONOS_URL" "SSH_PUBKEY")
for i in "${env_vars[@]}"; do
    if [ ! -z "$(env | grep ${i})" ]; then
        echo "checking ${i}"
        key=$(echo $(env | grep "${i}") | awk -F= '{print $1}') # first col
        val=$(echo $(env | grep "${i}"))
        val=${val#"${key}="}
        echo "export $key='$val'" >> ~/.bashrc
        echo "export $key='$val'" >> ~/.profile
        #echo "export $i='$(echo ${$i})'" >> ~/.bashrc
    fi
done

# Write iRODS environment configuration to files
if [ ! -z "$IRODS_PORT" ] && \
    [ ! -z "$IRODS_HOST" ] && \
    [ ! -z "$IRODS_USER_NAME" ] && \
    [ ! -z "$IRODS_ZONE_NAME" ]
then
    irods_environment='{
        "irods_port": '${IRODS_PORT}',
        "irods_host": "'${IRODS_HOST}'",
        "irods_user_name": "'${IRODS_USER_NAME}'",
        "irods_zone_name": "'${IRODS_ZONE_NAME}'"'

    if [ ! -z "$IRODS_HOME" ]; then
        irods_environment=${irods_environment}', "irods_home": "'${IRODS_HOME}'"'
    fi
    if [ ! -z "$IRODS_CWD" ]; then
        irods_environment=${irods_environment}', "irods_cwd": "'${IRODS_CWD}'"'
    fi
    if [ ! -z "$IRODS_AUTHENTICATION_SCHEME" ]; then
        irods_environment=${irods_environment}', "irods_authentication_scheme": "'${IRODS_AUTHENTICATION_SCHEME}'"'
        if [ ! -z "$IRODS_OPENID_PROVIDER" ]; then
            irods_environment=${irods_environment}', "openid_provider": "'${IRODS_OPENID_PROVIDER}'"'
        fi
    fi

    irods_environment=${irods_environment}' }'
    echo $irods_environment > ~/.irods/irods_environment.json
    sudo mkdir -p /etc/apache2/irods/
    echo $irods_environment | sudo tee /etc/apache2/irods/irods_environment.json
fi

# always use the zone as the cwd of the davrods connection
DAVRODS_ROOT='Zone'

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
        [%%DAVRODS_ROOT%%]=${DAVRODS_ROOT}
    )

    configurer() {
        # Loop the config array
        for i in "${!irods_config[@]}"
        do
            search=$i
            replace=${irods_config[$i]}
            #if [[ $replace == /* ]]; then replace='\'$replace; fi
            # Note the "" after -i, needed in OS X
            sudo sed -i "s|${search}|${replace}|g" /etc/apache2/sites-available/davrods-vhost.conf
        done
    }
    configurer
else
    echo "IRODS_PORT, IRODS_HOST, and IRODS_ZONE_NAME must defined for automated mount"
fi


if [ ! -f ~/.irods/.irodsA ]; then
    # irods not initialized
    echo "iRODS not initialized"
    if [ ! -z "${IRODS_AUTHENTICATION_SCHEME}" ] \
         && [ "${IRODS_AUTHENTICATION_SCHEME}" = "openid" ] \
         && ( [ ! -z "${IRODS_ACCESS_TOKEN}" ] || [ ! -z "${IRODS_USER_KEY}" ] ); then
        # davrods openid scheme
        sudo sed -i "s|DavRodsAuthScheme Native|DavRodsAuthScheme OpenID|g" /etc/apache2/sites-available/davrods-vhost.conf

        if [ ! -z "${IRODS_USER_KEY}" ]; then
            echo "Authenticating to iRODS using provided user key"
            echo "ukey=${IRODS_USER_KEY}" > ~/.irods/.irodsA
            echo "http://localhost:80 ${IRODS_USER_NAME} user_key=${IRODS_USER_KEY}" | sudo tee -a /etc/davfs2/secrets >> /dev/null
            # non-interactive iinit not currently implemented for user key
        elif [ ! -z "${IRODS_ACCESS_TOKEN}" ]; then
            echo "Authenticating to iRODS using provided access token"
            echo "act=${IRODS_ACCESS_TOKEN}" > ~/.irods/.irodsA
            echo "http://localhost:80 ${IRODS_USER_NAME} access_token=${IRODS_ACCESS_TOKEN}" | sudo tee -a /etc/davfs2/secrets >> /dev/null
            # test initial icommands conn, disable until also implemented for user key
            iinit "${IRODS_ACCESS_TOKEN}"
        else
            echo "entered unknown branch"
        fi
    elif [ ! -z "$IRODS_PASSWORD" ]; then
        echo "Authenticating to iRODS using provided password"
        echo "http://localhost:80 ${IRODS_USER_NAME} ${IRODS_PASSWORD}" | sudo tee -a /etc/davfs2/secrets >> /dev/null
        iinit "$IRODS_PASSWORD"
    else
        echo "Authenticating to iRODS using standard input"
        iinit
    fi
fi

export IRODS_MOUNT="/renci/irods"
sudo mkdir -p ${IRODS_MOUNT}
sudo chown -R dockeruser:datacommons ${IRODS_MOUNT}

# mount davrods
# begin ubuntu_specific
sudo a2enmod -q dav # WebDAV(davfs2) must be loaded before davrods
sudo a2enmod -q davrods
sudo a2dissite -q 000-default # turn off root site, shadows davrods
sudo a2ensite -q davrods-vhost
sudo a2ensite -q davrods-anonymous-vhost
sudo apache2ctl start
# end ubuntu_specific

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
    echo "Apache server did not start in under $wait_limit seconds"
fi

# now that apache with davrods module is up, mount it to fs
sudo mount -t davfs -o uid=dockeruser,gid=datacommons "http://localhost:80" ${IRODS_MOUNT}

# mount irods fuse
# allow fuse cross-user access so docker as root can see irods
#sudo sed -i 's/^#.*user_allow_other/user_allow_other/g' /etc/fuse.conf
# mount
#irodsFs -onocache -oallow_other /renci/irods
#!/bin/bash

cd ~/
. ~/.profile
#printf "ENTRYPOINT ENVIRONMENT\n\n"
#env

# make env vars persistent
declare -a env_vars=("PIVOT_URL" "CHRONOS_URL" "SSH_PUBKEY")
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

# /global is a global CephFS instance shared between all appliances/jobs
# /data is a CephFS instance for this particular appliance
# /workdir is some large-ish space for a working directory, which must be cleaned up
if [ -d /global ] && [ -d /data ]; then
    if [ -z "${APPLIANCE_ID}" ]; then
        echo "missing var APPLIANCE_ID"
        exit 1
    fi
    if [ -z "${JOB_ID}" ]; then
        echo "missing var JOB_ID"
        exit 1
    fi
    if [ -z "${METRICS_ENDPOINT}" ]; then
        echo "missing var METRICS_ENDPOINT"
        exit 1
    fi
    data_src_cloud="${DATA_SRC_CLOUD}"
    data_src_region="${DATA_SRC_REGION}"
    data_src_zone="${DATA_SRC_ZONE}"
    data_src_host="${DATA_SRC_HOST}"
    data_to="${DATA_TO}"
    #job_placement="${JOB_PLACEMENT}"


    # TODO maybe switch to rsync or other thing which gives better stats
    #tmpdir=$(mktemp -d)
    rsync_command=rsync -ra --out-format="%f %b"
    input_bytes=0
    # rsync global to workdir, should only transfer files on first workflow job
    initial_rsync_output=$(${rsync_command} /global /data)
    #if [ ! -z "${initial_rsync_output}" ]; then
    #    # parse rsync output to see how much it sent
    #    echo "Transferred data from global volume:"
    #    echo ${initial_rsync_output}
    #    IFS="
    #    "
    #    for line in initial_rsync_output; do
    #        file_size=$(echo $line | awk '{print $2}')
    #        input_bytes=$((input_bytes+file_size))
    #    done
    #fi

    transfer_bytes=$(du --summarize /data | awk '{print $1}')
    input_bytes=$((input_bytes+transfer_bytes))
    echo "INPUT_BYTES: ${input_bytes}"

    workdir="/workdir"
    #sudo mkdir -p ${workdir}
    sudo chown -R dockeruser:datacommons ${workdir}
    read_start=$(date +%s)
    rsync_output=$(${rsync_command} /data ${workdir})
    #cp -r /data/${APPLIANCE_ID}/* ${workdir}/
    read_end=$(date +%s)
    #mkdir -p /data/${APPLIANCE_ID}

    # Run args as command
    command_start=$(date +%s)
    "$@" & # this is to prevent exec abuse, by running in other process
    cmd_pid=$!
    echo "Waiting for pid ${cmd_pid} to finish."
    wait ${cmd_pid}
    command_end=$(date +%s)
    command_time=$((command_end-command_start))

    # write back workspace to mounted ceph volume
    write_start=$(date +%s)
    rsync_write_output=$(${rsync_command} ${workdir} /data)
    write_end=$(date +%s)
    read_time=$((read_end-read_start))
    write_time=$((write_end-write_start))

    # clean up workdir
    rm -rf ${workdir}/*

    body="{\"appliance\": \"${APPLIANCE_ID}\""
    body="${body}, \"job\": \"${JOB_ID}\""
    body="${body}, \"input_data_size\": \"${input_bytes}\""
    body="${body}, \"read_transfer_time\": \"${read_time}\""
    body="${body}, \"write_transfer_time\": \"${write_time}\""
    body="${body}, \"data_src_cloud\": \"${data_src_cloud}\""
    body="${body}, \"data_src_region\": \"${data_src_region}\""
    body="${body}, \"data_src_zone\": \"${data_src_zone}\""
    body="${body}, \"data_src_host\": \"${data_src_host}\""
    body="${body}, \"data_to\": \"${data_to}\""
    body="${body}, \"job_placement\": \"${job_placement}\""
    body="${body}, \"job_execution_time\": \"${command_time}\""
    body="${body}}"
    curl -X POST -d "${body}" "${METRICS_ENDPOINT}"
fi


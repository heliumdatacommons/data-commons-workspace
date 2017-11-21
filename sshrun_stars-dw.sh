#!/bin/bash

filename=$1

if [ -z "${filename}" ]; then
    echo "Enter path to script to run"; exit 1
fi
if [ ! -f "${filename}" ]; then
    echo "File not found:" $filename; exit 1
fi


logname="sshrun_stars-dw."$(date +%Y-%m-%d_%H-%M-%S)".log"

for i in {0..11}; do
    echo "Starting script on stars-dw${i} at" $(date +%Y-%m-%d_%H-%M-%S) | tee -a $logname
    ssh evryscope@stars-dw${i}.edc.renci.org "bash -s" < "${filename}" 2>&1 | tee -a $logname
    echo "Finished script on stars-dw${i} at" $(date +%Y-%m-%d_%H-%M-%S) | tee -a $logname
done

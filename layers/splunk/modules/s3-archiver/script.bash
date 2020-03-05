#!/bin/bash

set -ex

#bucket="pwsd-staging-syslog-archive"
if [[ $# != 4 ]]; then
   echo "$0 <daily_files> <gziped_files> <bucketname> <region_name> - all arguments are required"
   exit 1
fi

daily=$1
gziped=$2
bucket=$3
export AWS_DEFAULT_REGION=$4

function logger() {
    message=$1
    systemd-cat -t s3-archiver <<< ${message}
}

function remove() {
    file=$1
    rm ${file}
}

function gzip_file() {
    file=$1
    dest_file=$2
    gzip -c ${file} > ${dest_file}
}

function s3cmd() {
    source=$1
    bucket=$2
    key=$3
    aws s3 cp --no-progress ${source} s3://${bucket}/${key}
}

function send_to_s3(){
    bucket=$1
    dest_file=$2
    if [[ ! -f ${dest_file} ]]; then
        logger "WARN: ${dest_file} doesn't exist, exiting..."
        exit 1
    fi
    s3_file=$( basename ${dest_file} )
    s3cmd ${dest_file} ${bucket} ${s3_file}

    if aws s3api head-object --bucket ${bucket} --key ${s3_file} > /dev/null 2>&1; then
        logger "INFO: ${dest_file} successfully copied to s3://${bucket}/${s3_file}, remove ${dest_file}"
        remove ${dest_file}
    else
        logger "WARN: ${dest_file} failed to copy to s3://${bucket}/${s3_file}, will attempt to copy during next scheduled run"
    fi
}

dirname=$(dirname $0)
pushd ${dirname}/.. > /dev/null

[[ ! -d cronlog      ]] && install -m 0700 -d cronlog
[[ ! -d ${gziped} ]] && install -m 0700 -d ${gziped}

for file in $( find ${daily} -type f ! -newermt "$(date '+%Y-%m-%d 00:30:00')" -printf '%f\n' ); do
    logger "INFO: processing ${file}"
    daily_file="${daily}/${file}"
    dest_file="${gziped}/${file}.Z"

    if [[ ! -f ${dest_file} ]]; then
        gzip_file "${daily_file}" ${dest_file}
    fi

    if gzip -t ${dest_file}; then
        logger "INFO: successfully verfied the integrity of ${dest_file}"
        remove ${daily_file}
    else
        logger "WARN: ${dest_file} failed integrity test, discarding ${dest_file}, leaving ${file} for another gzip attempt"
    fi
done

for dest_file in $( find ${gziped} -type f); do
        logger "INFO sending ${dest_file} to s3"
        send_to_s3 ${bucket} ${dest_file}
done


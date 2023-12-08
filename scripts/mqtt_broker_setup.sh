#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8

# get a job on the a8 node. This is an existing node and we dont provide an elf file as well
# A8 nodes run Yocto by default
n_json=$(iotlab-experiment submit -n riot_a8_broker_g12 -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},a8,62)
n_node_job_id=$(echo $n_json | jq '.id')
wait_for_job "${n_node_job_id}"

sleep 20

ssh root@node-a8-62 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh

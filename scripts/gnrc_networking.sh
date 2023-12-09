#!/usr/bin/env bash

if [ -n "$SENSE_GNRC_NETWORKING_NODE_UP" ]; then
  echo "The broker bare bone node is already running."
  exit 0
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ARCH=iotlab-a8-m3
build_wireless_firmware_cached ${GNRC_NETWORKING_HOME} ${GNRC_NETWORKING_EXE_NAME} ${ARCH}
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then

  cp ${GNRC_NETWORKING_HOME}/bin/${ARCH}/${GNRC_NETWORKING_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

  n_json=$(iotlab-experiment submit -n ${GNRC_NETWORKING_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},a8,${GNRC_NETWORKING_NODE})
  n_node_job_id=$(echo $n_json | jq '.id')
  wait_for_job "${n_node_job_id}"
  iotlab-ssh flash-m3 ${SENSE_FIRMWARE_HOME}/${GNRC_NETWORKING_EXE_NAME}.elf -l saclay,a8,${GNRC_NETWORKING_NODE}

  export SENSE_GNRC_NETWORKING_NODE_UP=1
fi

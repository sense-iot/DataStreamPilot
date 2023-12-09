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

  if ! is_experiment_running "${GNRC_NETWORKING_EXE_NAME}"; then
    n_json=$(iotlab-experiment submit -n ${GNRC_NETWORKING_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},a8,${GNRC_NETWORKING_NODE})
    n_node_job_id=$(echo $n_json | jq '.id')
    wait_for_job "${n_node_job_id}"
  else
    n_node_job_id=$(get_running_experiment_id "${GNRC_NETWORKING_EXE_NAME}")
    echo "An experiment with the name ${GNRC_NETWORKING_EXE_NAME} is already running on ${n_node_job_id}."
  fi

  echo "Flashing new firmware for iotlab-a8-m3 node : ${GNRC_NETWORKING_NODE}"
  echo "iotlab-ssh flash-m3 ${SENSE_FIRMWARE_HOME}/${GNRC_NETWORKING_EXE_NAME}.elf -l ${SENSE_SITE},a8,${GNRC_NETWORKING_NODE}"
  iotlab-ssh -i ${n_node_job_id} flash ${SENSE_FIRMWARE_HOME}/${GNRC_NETWORKING_EXE_NAME}.elf -l ${SENSE_SITE},a8,${GNRC_NETWORKING_NODE}

  echo "ssh root@node-a8-${GNRC_NETWORKING_NODE}"
  echo "ping 2001:4860:4860::8888"
  export SENSE_GNRC_NETWORKING_NODE_UP=1
fi

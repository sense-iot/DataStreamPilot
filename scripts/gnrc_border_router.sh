#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh
source /opt/riot.source

RELEASE_FILE=${SENSE_HOME}/release/gnrc_border_router.elf
build_path=${BORDER_ROUTER_HOME}/bin/${ARCH}/${BORDER_ROUTER_EXE_NAME}.elf

echo "============== Building on channel ${NODE_CHANNEL} ================="
if [ ! -f "$RELEASE_FILE" ]; then
  echo "DataStreamPilot: build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3 ${DEFAULT_CHANNEL}"
  build_wireless_firmware ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3 ${DEFAULT_CHANNEL}
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
  cp $build_path $RELEASE_FILE
else
  echo "DataStreamPilot: File exists: $RELEASE_FILE"
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  # flash_elf ${RELEASE_FILE} ${BORDER_ROUTER_NODE}
  border_router_job_id_json=$(iotlab-experiment submit -n "${BORDER_ROUTER_EXE_NAME}_${SENSE_SITE}" -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},m3,${BORDER_ROUTER_NODE},${SENSE_HOME}/release/${BORDER_ROUTER_EXE_NAME}.elf)
  border_router_job_id=$(echo $border_router_job_id_json | jq -r '.id')
  wait_for_job "${border_router_job_id}"

  echo "ping6 2001:4860:4860::8888 -c 5"

  current_ethos_id=$(ps -ef | grep ethos | grep -v "grep" | grep perera | awk '{print $2}' | head -1)
  if [ -z "$current_ethos_id" ]; then
    echo "DataStreamPilot:  No matching ethos process found."
  else
    echo "DataStreamPilot: Ethos process ID: $current_ethos_id"
    echo "DataStreamPilot: Killing Ethos process ID $current_ethos_id"
    kill -9 $current_ethos_id
  fi
fi

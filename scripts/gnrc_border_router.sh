#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  if [ -n "$SENSE_BORDER_ROUTER_UP" ]; then
    return 0
  fi
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

file_to_check=${SENSE_HOME}/release/gnrc_border_router.elf

if [ ! -f "$file_to_check" ]; then
  echo "build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3"
  build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
  ELF_FILE=${BORDER_ROUTER_HOME}/bin/${ARCH}/${BORDER_ROUTER_EXE_NAME}.elf
else
  echo "File exists: $file_to_check"
  ELF_FILE=$file_to_check
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp $ELF_FILE ${SENSE_FIRMWARE_HOME}

  flash_firmware ${BORDER_ROUTER_EXE_NAME} ${BORDER_ROUTER_NODE}

  current_ethos_id=$(ps -ef | grep ethos | grep -v "grep" | grep perera | awk '{print $2}' | head -1)
  if [ -z "$current_ethos_id" ]; then
    echo "No matching ethos process found."
  else
    echo "Ethos process ID: $current_ethos_id"
    echo "Killing Ethos process ID $current_ethos_id"
    kill -9 $current_ethos_id
  fi

  create_tap_interface "${BORDER_ROUTER_NODE}" &

  export SENSE_BORDER_ROUTER_UP=1
fi

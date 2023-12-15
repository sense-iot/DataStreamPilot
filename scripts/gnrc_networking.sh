#!/usr/bin/env bash

if [ -n "$SENSE_GNRC_NETWORKING_NODE_UP" ]; then
  echo "The broker bare bone node is already running."
  exit 0
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

# File to check
file_to_check=${SENSE_HOME}/release/gnrc_networking.elf

# Check if the file exists
if [ ! -f "$file_to_check" ]; then
  build_wireless_firmware_cached ${GNRC_NETWORKING_HOME} ${GNRC_NETWORKING_EXE_NAME} iotlab-a8-m3
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
  cp $ELF_FILE ~/A8

  echo "Flashing new firmware for iotlab-a8-m3 node : ${GNRC_NETWORKING_NODE}"
  ssh root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/gnrc_networking_a8/flash.sh

  export SENSE_GNRC_NETWORKING_NODE_UP=1
fi

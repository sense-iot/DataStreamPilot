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
  cp ${GNRC_NETWORKING_HOME}/bin/${ARCH}/${GNRC_NETWORKING_EXE_NAME}.elf ~/A8

  echo "Flashing new firmware for iotlab-a8-m3 node : ${GNRC_NETWORKING_NODE}"
  ssh root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/gnrc_networking_a8/border.sh
fi

#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  if [ -n "$SENSE_BORDER_ROUTER_UP" ]; then
    return 0
  fi
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

echo "build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3"

build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} iotlab-m3
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${BORDER_ROUTER_HOME}/bin/${ARCH}/${BORDER_ROUTER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

  flash_firmware ${BORDER_ROUTER_EXE_NAME} ${BORDER_ROUTER_NODE}
  create_tap_interface "${BORDER_ROUTER_NODE}" &
  
  export SENSE_BORDER_ROUTER_UP=1
fi
#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  if [ -n "$SENSE_BORDER_ROUTER_UP" ]; then
    return 0
  fi
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

file_to_check=${SENSE_HOME}/release/gnrc_border_router_a8.elf
my_arch=iotlab-a8-m3
if [ ! -f "$file_to_check" ]; then
  echo "build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} ${my_arch} ${DEFAULT_CHANNEL_2}" 
  build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME} ${my_arch} ${DEFAULT_CHANNEL_2}
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
  ELF_FILE=${BORDER_ROUTER_HOME}/bin/${my_arch}/${BORDER_ROUTER_EXE_NAME}.elf
else
  echo "File exists: $file_to_check"
  ELF_FILE=$file_to_check
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp $ELF_FILE ${SENSE_FIRMWARE_HOME}
  cp $ELF_FILE ${SENSE_HOME}/release/gnrc_border_router_a8.elf
  cp $ELF_FILE ~/A8/gnrc_border_router_a8.elf

  echo "Flashing new firmware for iotlab-a8-m3 node : ${BORDER_ROUTER_NODE_a8}"
  until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${BORDER_ROUTER_NODE_a8} 'bash -s' <${SENSE_HOME}/src/network/gnrc_border_router/flash.sh; do
    echo "------------------------------------------"
    echo "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${BORDER_ROUTER_NODE_a8} 'bash -s' <${SENSE_HOME}/src/network/gnrc_border_router/flash.sh"
    echo "Error: ssh failed to broker. Retrying...!"
    echo "------------------------------------------"
    sleep 10
  done

  export SENSE_BORDER_ROUTER_UP=1
fi
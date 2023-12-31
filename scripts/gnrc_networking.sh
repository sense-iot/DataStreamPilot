#!/usr/bin/env bash

if [ -n "$SENSE_GNRC_NETWORKING_NODE_UP" ]; then
  echo "DataStreamPilot: The broker bare bone node is already running."
  exit 0
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

# File to check
file_to_check=${SENSE_HOME}/release/gnrc_networking.elf
my_arch=${ARCH}

# Check if the file exists
if [ ! -f "$file_to_check" ]; then
  build_wireless_firmware ${GNRC_NETWORKING_HOME} ${GNRC_NETWORKING_EXE_NAME} iotlab-a8-m3 ${DEFAULT_CHANNEL}
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
  ELF_FILE=${GNRC_NETWORKING_HOME}/bin/iotlab-a8-m3/${GNRC_NETWORKING_EXE_NAME}.elf
else
  echo "DataStreamPilot: File exists: $file_to_check"
  ELF_FILE=$file_to_check
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then

  cp $ELF_FILE ${SENSE_FIRMWARE_HOME}
  cp $ELF_FILE ${SENSE_HOME}/release/${GNRC_NETWORKING_EXE_NAME}.elf
  cp $ELF_FILE ~/A8

  echo "DataStreamPilot: Flashing new firmware for iotlab-a8-m3 node : ${GNRC_NETWORKING_NODE}"
  until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/gnrc_networking_a8/flash.sh; do
    echo "DataStreamPilot: ------------------------------------------"
    echo "DataStreamPilot: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/gnrc_networking_a8/flash.sh"
    echo "DataStreamPilot: Error: ssh failed to broker. Retrying...!"
    echo "DataStreamPilot: ------------------------------------------"
    sleep 10
  done

  export SENSE_GNRC_NETWORKING_NODE_UP=1
fi

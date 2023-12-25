#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

echo "============== Building on channel ${NODE_CHANNEL} ================="

my_arch=${ARCH}

file_to_check="${SENSE_HOME}/release/${COAP_SERVER_EXE_NAME}.elf"

if [ ! -f "$file_to_check" ]; then
  echo "DataStereamPilot: ELF NOT FOUND"
  build_wireless_firmware ${COAP_SERVER_HOME} ${COAP_SERVER_EXE_NAME} ${my_arch} ${NODE_CHANNEL}
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
else
  echo "DataStereamPilot: File exists: $file_to_check"
  ELF_FILE=$file_to_check
  flash_firmware ${COAP_SERVER_EXE_NAME} ${COAP_SERVER_NODE}
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  echo "DataStereamPilot: Copy firmware files to shared"
  echo "cp ${COAP_SERVER_HOME}/bin/${ARCH}/${COAP_SERVER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}"
  echo " cp ${COAP_SERVER_HOME}/bin/${ARCH}/${COAP_SERVER_EXE_NAME}.elf  ${SENSE_HOME}/release/"

  cp ${COAP_SERVER_HOME}/bin/${ARCH}/${COAP_SERVER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

  cp ${COAP_SERVER_HOME}/bin/${ARCH}/${COAP_SERVER_EXE_NAME}.elf ${SENSE_HOME}/release/

  echo "DataStereamPilot: Flashing new firmware for ${my_arch} node : ${COAP_SERVER_NODE}"
  
  echo "nc m3-${COAP_SERVER_NODE} 20000"

fi

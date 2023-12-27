#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

# if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
#   echo "DataStreamPilot: The broker IP has changed ${BROKER_IP}."
#   export PREV_BROKER_IP=${BROKER_IP}
#   build_wireless_firmware ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-m3
# else
#   echo "DataStreamPilot: The broker IP has not changed ${BROKER_IP}."
#   export PREV_BROKER_IP=${BROKER_IP}
#   build_wireless_firmware_cached ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-m3
# fi
my_arch=${ARCH}

file_to_check=${SENSE_HOME}/release/emcute_mqttsn_d.elf
my_arch=${ARCH}

# Check if the file exists
if [ ! -f "$file_to_check" ]; then
  build_wireless_firmware ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} ${my_arch} ${NODE_CHANNEL}
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi
  ELF_FILE=${EMCUTE_MQTSSN_HOME}/bin/${ARCH}/${EMCUTE_MQTSSN_EXE_NAME}.elf
else
  echo "DataStreamPilot: File exists: $file_to_check"
  ELF_FILE=$file_to_check
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp $ELF_FILE ${SENSE_FIRMWARE_HOME}
  cp $ELF_FILE ${SENSE_HOME}/release/${EMCUTE_MQTSSN_EXE_NAME}_${EMCUTE_ID}.elf

  echo "DataStreamPilot:Flashing new firmware for ${ARCH} node : ${DENOISER_NODE}"
  flash_firmware ${EMCUTE_MQTSSN_EXE_NAME} ${DENOISER_NODE}

  echo "DataStreamPilot: ping 2001:4860:4860::8888"
  echo "DataStreamPilot: nc m3-${DENOISER_NODE} 20000"
  echo "DataStreamPilot: con 2001:660:5307:3000::67 1885"
  echo "DataStreamPilot: pub temperature 32.5"
  echo "DataStreamPilot: nc m3-${DENOISER_NODE} 20000"

  echo "nc m3-${DENOISER_NODE} 20000"
fi

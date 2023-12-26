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

build_wireless_firmware ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} ${my_arch} ${NODE_CHANNEL}
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${EMCUTE_MQTSSN_HOME}/bin/iotlab-m3/${EMCUTE_MQTSSN_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  cp ${EMCUTE_MQTSSN_HOME}/bin/${my_arch}/${EMCUTE_MQTSSN_EXE_NAME}.elf ${SENSE_HOME}/release/${EMCUTE_MQTSSN_EXE_NAME}_${EMCUTE_ID}.elf

  echo "DataStreamPilot:Flashing new firmware for ${ARCH} node : ${DENOISER_NODE}"
  flash_firmware ${EMCUTE_MQTSSN_EXE_NAME} ${DENOISER_NODE}

  echo "DataStreamPilot: ping 2001:4860:4860::8888"
  echo "DataStreamPilot: nc m3-${DENOISER_NODE} 20000"
  echo "DataStreamPilot: con 2001:660:5307:3000::67 1885"
  echo "DataStreamPilot: pub temperature 32.5"
  echo "DataStreamPilot: nc m3-${DENOISER_NODE} 20000"

  echo "nc m3-${DENOISER_NODE} 20000"
fi

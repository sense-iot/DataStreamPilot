#!/usr/bin/env bash

if [ -n "$EMCUTE_MQTTSN_NODE_UP" ]; then
  echo "The EMCUTE_MQTTSN_NODE_UP is already running."
  exit 0
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
    export PREV_BROKER_IP=${BROKER_IP}
    build_wireless_firmware ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-a8-m3
else
    echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
    export PREV_BROKER_IP=${BROKER_IP}
    build_wireless_firmware_cached ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-a8-m3
fi
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${EMCUTE_MQTSSN_HOME}/bin/iotlab-a8-m3/${EMCUTE_MQTSSN_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  cp ${EMCUTE_MQTSSN_HOME}/bin/iotlab-a8-m3/${EMCUTE_MQTSSN_EXE_NAME}.elf ~/A8

  echo "Flashing new firmware for ${ARCH} node : ${MQTT_CLIENT_NODE}"
  # flash_firmware ${EMCUTE_MQTSSN_EXE_NAME} ${MQTT_CLIENT_NODE}
  ssh root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_a8/flash.sh

  export EMCUTE_MQTTSN_NODE_UP=1
fi

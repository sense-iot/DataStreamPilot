#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
  echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
  export PREV_BROKER_IP=${BROKER_IP}
  build_wireless_firmware ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-m3
else
  echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
  export PREV_BROKER_IP=${BROKER_IP}
  build_wireless_firmware_cached ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-m3
fi

build_wireless_firmware ${EMCUTE_MQTSSN_CLIENT_HOME} ${EMCUTE_MQTSSN_EXE_NAME} iotlab-m3
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${EMCUTE_MQTSSN_CLIENT_HOME}/bin/iotlab-m3/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  cp ${EMCUTE_MQTSSN_CLIENT_HOME}/bin/iotlab-m3/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}.elf ${SENSE_HOME}/release/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf

  echo "Flashing new firmware for ${ARCH} node : ${MQTT_CLIENT_NODE}"
  flash_firmware ${EMCUTE_MQTSSN_CLIENT_EXE_NAME} ${MQTT_CLIENT_NODE}
  # echo "nc m3-${MQTT_CLIENT_NODE} 20000"
  echo "nc m3-${MQTT_CLIENT_NODE} 20000"
  # nc m3-${MQTT_CLIENT_NODE} 20000
fi

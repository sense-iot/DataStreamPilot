#!/usr/bin/env bash

if [ -n "$EMCUTE_MQTTSN_NODE_UP" ]; then
  echo "The EMCUTE_MQTTSN_NODE_UP is already running."
  exit 0
fi

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

build_wireless_firmware_cached ${EMCUTE_MQTSSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME} ${ARCH}
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then

  cp ${EMCUTE_MQTSSN_HOME}/bin/${ARCH}/${EMCUTE_MQTSSN_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

  echo "Flashing new firmware for ${ARCH} node : ${MQTT_CLIENT_NODE}"
  flash_firmware ${EMCUTE_MQTSSN_EXE_NAME} ${MQTT_CLIENT_NODE}

  export EMCUTE_MQTTSN_NODE_UP=1
fi

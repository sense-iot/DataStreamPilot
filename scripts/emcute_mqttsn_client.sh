#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

my_arch=${ARCH}

build_wireless_firmware ${EMCUTE_MQTSSN_CLIENT_HOME} ${EMCUTE_MQTSSN_EXE_NAME} ${my_arch}
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${EMCUTE_MQTSSN_CLIENT_HOME}/bin/${my_arch}/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  cp ${EMCUTE_MQTSSN_CLIENT_HOME}/bin/iotlab-m3/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}.elf ${SENSE_HOME}/release/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf

  if [ "$my_arch" = "iotlab-m3" ]; then
      echo "Architecture is iotlab-m3."
      echo "Flashing new firmware for ${my_arch} node : ${MQTT_CLIENT_NODE}"
      flash_firmware ${EMCUTE_MQTSSN_CLIENT_EXE_NAME} ${MQTT_CLIENT_NODE}
      echo "nc m3-${MQTT_CLIENT_NODE} 20000"
  elif [ "$my_arch" = "iotlab-a8-m3" ]; then
      cp ${EMCUTE_MQTSSN_CLIENT_HOME}/bin/${my_arch}/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}.elf ~/A8/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf
      echo "Architecture is iotlab-a8-m3."
      ssh -oStrictHostKeyChecking=accept-new root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
      echo "ssh root@node-a8-${MQTT_CLIENT_NODE}"
  else
      echo "Architecture is something else."
  fi
fi

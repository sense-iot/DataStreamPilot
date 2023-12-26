#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStreamPilot: The broker IP has changed ${BROKER_IP}."
    export PREV_BROKER_IP=${BROKER_IP}
    build_wireless_firmware ${ASYMCUTE_MQTTSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME}
else
    echo "DataStreamPilot: The broker IP has not changed ${BROKER_IP}."
    export PREV_BROKER_IP=${BROKER_IP}
    build_wireless_firmware_cached ${ASYMCUTE_MQTTSN_HOME} ${EMCUTE_MQTSSN_EXE_NAME}
fi
build_status=$?
if [ $build_status -ne 0 ]; then
  exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  cp ${ASYMCUTE_MQTTSN_HOME}/bin/iotlab-m3/${ASYMCUTE_MQTTSN_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
  # rm ~/A8/${PAHO_MQTT_EXE_NAME}.elf
  # cp ${ASYMCUTE_MQTTSN_HOME}/bin/iotlab-m3/${ASYMCUTE_MQTTSN_EXE_NAME}.elf ~/A8

  MQTT_CLIENT_NODE=$(read_variable_from_file "MQTT_CLIENT_NODE")
  echo "Flashing new firmware for iotlab-m3 node : ${MQTT_CLIENT_NODE}"
  flash_firmware ${ASYMCUTE_MQTTSN_EXE_NAME} ${MQTT_CLIENT_NODE}
  # ssh root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${ASYMCUTE_MQTTSN_HOME}/flash.sh


#con  <broker ip addr> [port] [clientID] [user] [password] [keepalivetime]

 nc m3-${MQTT_CLIENT_NODE} 20000
 #echo "con 2001:660:5307:3000::68 1886"
 #pub temperature "32.5"


fi

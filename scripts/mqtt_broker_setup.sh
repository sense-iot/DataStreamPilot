#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh


cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8


echo "Staring the MQTT broker"
ssh root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh
export BROKER_IP=$(extract_global_ipv6)
echo "DataStereamPilot: mqtt broker ip is : $BROKER_IP"

write_variable_to_file "BROKER_IP" "$BROKER_IP"

BROKER_IP=$(read_variable_from_file "BROKER_IP")
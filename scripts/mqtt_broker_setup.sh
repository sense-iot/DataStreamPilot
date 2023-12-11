#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh


cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8


echo "Staring the MQTT broker"
ssh root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh
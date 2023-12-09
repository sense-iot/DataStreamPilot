#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

${SENSE_SCRIPTS_HOME}/gnrc_networking.sh

cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8

sleep 60

ssh root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh
#ip -6 -o addr show eth0

#con 2001:660:5307:3000::3e 1885

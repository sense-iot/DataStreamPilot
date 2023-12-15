#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

export CLIENT_TOPIC="sens1_temperature"
ip_address=$(read_variable_from_file "BROKER_IP")
echo "mosquitto_sub -h $ip_address -p 1883 -t dead_sensors"
mosquitto_sub -h $ip_address -p 1883 -t dead_sensors
#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

export CLIENT_TOPIC="sens2_temperature"
ip_address=$(read_variable_from_file "BROKER_IP")
echo "mosquitto_sub -h $ip_address -p 1883 -t $CLIENT_TOPIC"
mosquitto_sub -h $ip_address -p 1883 -t $CLIENT_TOPIC
#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ip_address=$(read_variable_from_file "BROKER_IP")
echo "mosquitto_sub -h $ip_address -p 1883 -t temperature"
mosquitto_sub -h $ip_address -p 1883 -t temperature
#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ip_address=$(read_variable_from_file "BROKER_IP")
echo "mosquitto_pub -h $ip_address -p 1883 -t temperature -m $1"
mosquitto_pub -h $ip_address -p 1883 -t temperature -m $1
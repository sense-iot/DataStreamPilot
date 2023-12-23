#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh
export CLIENT_TOPIC="s1"
ip_address=$(extract_global_ipv6)
echo "mosquitto_sub -h $ip_address -p 1883 -t $CLIENT_TOPIC"
mosquitto_sub -h $ip_address -p 1883 -t $CLIENT_TOPIC
#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ip_address=$(read_variable_from_file "BROKER_IP")
echo "mosquitto_pub -h $ip_address -p 1883 -t sens1_temperature -m $1"
mosquitto_pub -h $ip_address -p 1883 -t sens1_temperature -m $1 -q 2

echo "mosquitto_pub -h $ip_address -p 1883 -t sens2_temperature -m $1"
mosquitto_pub -h $ip_address -p 1883 -t sens2_temperature -m $1

echo "mosquitto_pub -h $ip_address -p 1883 -t sens3_temperature -m $1"
mosquitto_pub -h $ip_address -p 1883 -t sens3_temperature -m $1
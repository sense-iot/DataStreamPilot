#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ip_address=$(extract_global_ipv6)
echo "mosquitto_pub -h $ip_address -p 1883 -t s1 -m $1"
mosquitto_pub -h $ip_address -p 1883 -t s1 -m $1 -q 2

echo "mosquitto_pub -h $ip_address -p 1883 -t s2 -m $2"
mosquitto_pub -h $ip_address -p 1883 -t s2 -m $2

echo "mosquitto_pub -h $ip_address -p 1883 -t s3 -m $3"
mosquitto_pub -h $ip_address -p 1883 -t s3 -m $3
#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

ip_address=$(extract_global_ipv6)

if [ -n "$1" ]; then 
    echo "mosquitto_pub -h $ip_address -p 1886 -t s1 -m $1"
    mosquitto_pub -h $ip_address -p 1886 -t s1 -m $1
fi

if [ -n "$2" ]; then 
    echo "mosquitto_pub -h $ip_address -p 1886 -t s2 -m $2"
    mosquitto_pub -h $ip_address -p 1886 -t s2 -m $2
fi

if [ -n "$3" ]; then 
    echo "mosquitto_pub -h $ip_address -p 1886 -t s3 -m $3"
    mosquitto_pub -h $ip_address -p 1886 -t s3 -m $3
fi

if [ -n "$4" ]; then
    echo "mosquitto_pub -h $ip_address -p 1886 -t d -m $4"
    mosquitto_pub -h $ip_address -p 1886 -t d -m $4
fi
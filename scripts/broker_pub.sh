#!/usr/bin/env bash

ip_address=$(read_variable_from_file "BROKER_IP")
mosquitto_pub -h $ip_address -p 1886 -t test/riot -m "$1"
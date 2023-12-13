#!/usr/bin/env bash

ip -6 -o addr show eth0 
ifconfig eth0 > ~/shared/mqtt_broker_details.txt
broker_mqtts ~/A8/broker_config.conf &

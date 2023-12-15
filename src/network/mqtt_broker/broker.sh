#!/usr/bin/env bash

ip -6 -o addr show eth0
ifconfig eth0 >~/shared/mqtt_broker_details.txt
current_mqtt_id=$(ps -ef | grep mosquitto | head -1 | awk '{print $2}')

if [ -z "$current_mqtt_id" ]; then
    echo "No matching ethos process found."
else
    echo "Killing current_mqtt_id $current_mqtt_id"
    kill -9 $current_mqtt_id
fi

current_broker=$(ps -ef | grep broker_mqtts | head -1 | awk '{print $2}')
echo "Killing current_broker $current_broker"
kill -9 $current_broker
echo "broker_mqtts -v ~/A8/broker_config.conf"
broker_mqtts -v ~/A8/broker_config.conf >/dev/null 2>&1 &
ps -ef | grep broker | head -1
netstat -tuln | grep LISTEN
exit

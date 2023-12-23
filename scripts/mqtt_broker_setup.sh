#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh


cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8
source /opt/riot.source
echo "DataStereamPilot: removing mqtt_broker_details.txt file"
rm ~/shared/mqtt_broker_details.txt
echo "DataStereamPilot: Staring the MQTT broker"
until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh
do
    echo "DataStereamPilot: ------------------------------------------"
    echo "DataStereamPilot: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh"
    echo "DataStereamPilot: Error: ssh failed to broker. Retrying...!"
    echo "DataStereamPilot: ------------------------------------------"
    sleep 10
done

export BROKER_IP=$(extract_global_ipv6)
echo "DataStereamPilot: mqtt broker ip is : $BROKER_IP"
write_variable_to_file "BROKER_IP" "$BROKER_IP"
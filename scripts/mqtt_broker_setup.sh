#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh


cp ${SENSE_HOME}/src/network/mqtt_broker/broker_config.conf ~/A8
source /opt/riot.source
echo "DataStreamPilot: removing mqtt_broker_details.txt file"
rm ~/shared/mqtt_broker_details.txt
echo "DataStreamPilot: Staring the MQTT broker"
until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh
do
    echo "DataStreamPilot: ------------------------------------------"
    echo "DataStreamPilot: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/mqtt_broker/broker.sh"
    echo "DataStreamPilot: Error: ssh failed to broker. Retrying...!"
    echo "DataStreamPilot: ------------------------------------------"
    sleep 10
done

export BROKER_IP=$(extract_global_ipv6)
echo "DataStreamPilot: mqtt broker ip is : $BROKER_IP"
write_variable_to_file "BROKER_IP" "$BROKER_IP"
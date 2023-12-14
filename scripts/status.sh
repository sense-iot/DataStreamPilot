#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
EXPERIMENT_ID=$(read_experiment_id)
echo "DataStereamPilot: Current experiment ID : ${EXPERIMENT_ID}"

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStereamPilot: Experiment '${EXPERIMENT_NAME}' not running"
    exit 0
fi

nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
extract_and_categorize_nodes "$nodes_list"

# Access and use the global arrays
echo "DataStereamPilot: a8 nodes: ${a8_nodes[@]}"
echo "DataStereamPilot: m3 nodes: ${m3_nodes[@]}"

MQTT_CLIENT_NODE=$(read_variable_from_file "MQTT_CLIENT_NODE")
BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
GNRC_NETWORKING_NODE=$(read_variable_from_file "GNRC_NETWORKING_NODE")
SENSOR_CONNECTED_NODE=$(read_variable_from_file "SENSOR_CONNECTED_NODE")

printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"


printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: SENSOR_CONNECTED_NODE:" "m3 - $SENSOR_CONNECTED_NODE"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE:" "m3 - $MQTT_CLIENT_NODE"


echo " ----- M3 - A8 nodes ----- "
echo "ssh root@node-a8-${GNRC_NETWORKING_NODE}"


echo " ----- M3 nodes ----- "
echo "nc m3-${BORDER_ROUTER_NODE} 20000"
echo "nc m3-${SENSOR_CONNECTED_NODE} 20000"
echo "nc m3-${MQTT_CLIENT_NODE} 20000"

echo "Broker IP : $(extract_global_ipv6)"
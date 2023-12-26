#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
EXPERIMENT_ID=$(read_experiment_id)
echo "DataStreamPilot: Current experiment ID : ${EXPERIMENT_ID}"

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStreamPilot: Experiment '${EXPERIMENT_NAME}' not running"
    exit 0
fi

nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
extract_and_categorize_nodes "$nodes_list"

# Access and use the global arrays
echo "DataStreamPilot: a8 nodes: ${a8_nodes[@]}"
echo "DataStreamPilot: m3 nodes: ${m3_nodes[@]}"

GNRC_NETWORKING_NODE=$(read_variable_from_file "GNRC_NETWORKING_NODE")
BROKER_DISCOVERY_NODE=$(read_variable_from_file "BROKER_DISCOVERY_NODE")
COMPUTER_ENGINE_NODE=$(read_variable_from_file "COMPUTER_ENGINE_NODE")

MQTT_CLIENT_NODE_1=$(read_variable_from_file "MQTT_CLIENT_NODE_1")
MQTT_CLIENT_NODE_2=$(read_variable_from_file "MQTT_CLIENT_NODE_2")
MQTT_CLIENT_NODE_3=$(read_variable_from_file "MQTT_CLIENT_NODE_3")
BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
SENSOR_CONNECTED_NODE=$(read_variable_from_file "SENSOR_CONNECTED_NODE")
DENOISER_NODE=$(read_variable_from_file "DENOISER_NODE")
BORDER_ROUTER_NODE_a8=$(read_variable_from_file "BORDER_ROUTER_NODE_a8")
COAP_SERVER_NODE=$(read_variable_from_file "COAP_SERVER_NODE")

printf "%-50s %s\n" "DataStreamPilot: GNRC_NETWORKING_NODE: " "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStreamPilot: BORDER_ROUTER_NODE: " "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStreamPilot: DENOISER_NODE: " "m3 - $DENOISER_NODE"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_1: " "m3 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_2: " "m3 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_3: " "m3 - $MQTT_CLIENT_NODE_3"
printf "%-50s %s\n" "DataStreamPilot: BROKER_DISCOVERY_NODE: " "m3 - $BROKER_DISCOVERY_NODE"
printf "%-50s %s\n" "DataStreamPilot: COMPUTER_ENGINE_NODE: " "m3 - $COMPUTER_ENGINE_NODE"
printf "%-50s %s\n" "DataStreamPilot: COAP_SERVER_NODE: " "m3 - $COAP_SERVER_NODE"

echo " ----- M3 - A8 nodes ----- "
echo "ssh root@node-a8-${GNRC_NETWORKING_NODE}  # mqtt broker"

echo " ----- M3 nodes ----- "
echo "nc m3-${BORDER_ROUTER_NODE} 20000   # border router"
echo "nc m3-${DENOISER_NODE} 20000   # border router"
echo "nc m3-${MQTT_CLIENT_NODE_1} 20000   # sensor 1"
echo "nc m3-${MQTT_CLIENT_NODE_2} 20000   # sensor 2"
echo "nc m3-${MQTT_CLIENT_NODE_3} 20000    # sensor 3"
echo "nc m3-${BROKER_DISCOVERY_NODE} 20000 # BROKER_DISCOVERY_NODE"
echo "nc m3-${COMPUTER_ENGINE_NODE} 20000 # COMPUTER_ENGINE_NODE"
echo "nc m3-${COAP_SERVER_NODE} 20000 # COAP_SERVER_NODE"


echo "Broker IP 1 : $(extract_global_ipv6)"
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
COMPUTE_ENGINE_NODE=$(read_variable_from_file "COMPUTE_ENGINE_NODE")

MQTT_CLIENT_NODE_1=$(read_variable_from_file "MQTT_CLIENT_NODE_1")
MQTT_CLIENT_NODE_2=$(read_variable_from_file "MQTT_CLIENT_NODE_2")
MQTT_CLIENT_NODE_3=$(read_variable_from_file "MQTT_CLIENT_NODE_3")
BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
DENOISER_NODE=$(read_variable_from_file "DENOISER_NODE")

printf "%-50s %s\n" "DataStreamPilot: GNRC_NETWORKING_NODE  :   " "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStreamPilot: BORDER_ROUTER_NODE    :   " "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStreamPilot: DENOISER_NODE         :   " "m3 - $DENOISER_NODE"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_1    :   " "m3 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_2    :   " "m3 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStreamPilot: MQTT_CLIENT_NODE_3    :   " "m3 - $MQTT_CLIENT_NODE_3"
printf "%-50s %s\n" "DataStreamPilot: COMPUTE_ENGINE_NODE   :   " "m3 - $COMPUTE_ENGINE_NODE"

echo " ----- M3 - A8 nodes ----- "
echo "ssh root@node-a8-${GNRC_NETWORKING_NODE}  # mqtt broker"

echo " ----- M3 nodes ----- "
printf "nc m3-%03d 20000   # border router node\n" $BORDER_ROUTER_NODE
printf "nc m3-%03d 20000   # denoiser node\n" $DENOISER_NODE
printf "nc m3-%03d 20000   # sensor_1 node\n" $MQTT_CLIENT_NODE_1
printf "nc m3-%03d 20000   # sensor_2 node\n" $MQTT_CLIENT_NODE_2
printf "nc m3-%03d 20000   # sensor_3 node\n" $MQTT_CLIENT_NODE_3
printf "nc m3-%03d 20000   # computer engine node\n" $COMPUTE_ENGINE_NODE

echo "Broker IP 1 : $(extract_global_ipv6)"
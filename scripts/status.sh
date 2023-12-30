#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12-$SENSE_SITE"
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
COMPUTE_ENGINE_NODE_1=$(read_variable_from_file "COMPUTE_ENGINE_NODE_3")
COMPUTE_ENGINE_NODE_2=$(read_variable_from_file "COMPUTE_ENGINE_NODE_2")
COMPUTE_ENGINE_NODE_3=$(read_variable_from_file "COMPUTE_ENGINE_NODE_1")

printf "%-50s %s\n" "DataStreamPilot: BORDER_ROUTER_NODE    :   " "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStreamPilot: COMPUTE_ENGINE_NODE_1    :   " "m3 - $COMPUTE_ENGINE_NODE_1"
printf "%-50s %s\n" "DataStreamPilot: COMPUTE_ENGINE_NODE_2    :   " "m3 - $COMPUTE_ENGINE_NODE_2"
printf "%-50s %s\n" "DataStreamPilot: COMPUTE_ENGINE_NODE_3    :   " "m3 - $COMPUTE_ENGINE_NODE_3"

echo " ----- M3 nodes ----- "
printf "nc m3-%d 20000   # border router node\n" $BORDER_ROUTER_NODE
printf "nc m3-%d 20000   # sensor_1 node\n" $COMPUTE_ENGINE_NODE_1
printf "nc m3-%d 20000   # sensor_2 node\n" $COMPUTE_ENGINE_NODE_2
printf "nc m3-%d 20000   # sensor_3 node\n" $COMPUTE_ENGINE_NODE_3

# echo "Broker IP 1 : $(extract_global_ipv6)"
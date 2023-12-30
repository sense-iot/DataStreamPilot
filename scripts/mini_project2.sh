#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

export ARCH=iotlab-m3

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=4
A8_NODE_COUNT=0
EXPERIMENT_ID=0

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStreamPilot: submitting a new experiment"
    experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d ${EXPERIMENT_TIME} -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE} -l $A8_NODE_COUNT,archi=a8:at86rf231+site=${SENSE_SITE})
    EXPERIMENT_ID=$(echo $experiment_out | jq '.id')
    wait_for_job "${EXPERIMENT_ID}"
else
    EXPERIMENT_ID=$(get_running_experiment_id "${EXPERIMENT_NAME}")
    echo "DataStreamPilot: An experiment with the name '${EXPERIMENT_NAME}' is already running on '${EXPERIMENT_ID}'."
    wait_for_job "${EXPERIMENT_ID}"
fi

write_experiment_id "$EXPERIMENT_ID"
nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
extract_and_categorize_nodes "$nodes_list"

if [ ${#m3_nodes[@]} -lt ${M3_NODE_COUNT} ]; then
    echo "DataStreamPilot: [Error] Not enough m3 nodes."
    exit 1
fi


# assign a8 nodes
export GNRC_NETWORKING_NODE=${a8_nodes[0]}

# assign m3 nodes
export BORDER_ROUTER_NODE=${m3_nodes[0]}
export COMPUTE_ENGINE_NODE_1=${m3_nodes[1]}
export COMPUTE_ENGINE_NODE_2=${m3_nodes[2]}
export COMPUTE_ENGINE_NODE_3=${m3_nodes[3]}

write_and_print_variable "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_1" "$COMPUTE_ENGINE_NODE_1" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_2" "$COMPUTE_ENGINE_NODE_2" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_3" "$COMPUTE_ENGINE_NODE_3" "m3"

echo "DataStreamPilot: I am sleeping for nodes to start..."
sleep 5

export NODE_CHANNEL=${DEFAULT_CHANNEL}
echo "================ Border Router and Broker node =========================="
echo "========= starting gnrc_border_router node ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh

echo "=============== Starting Compute Engine ==================="
export EMCUTE_ID="s1"
export CLIENT_TOPIC="s1"
export NODE_CHANNEL=${DEFAULT_CHANNEL}
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_1}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh

export EMCUTE_ID="s2"
export CLIENT_TOPIC="s2"
export NODE_CHANNEL=${DEFAULT_CHANNEL}
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_1}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh

export EMCUTE_ID="s3"
export CLIENT_TOPIC="s3"
export NODE_CHANNEL=${DEFAULT_CHANNEL}
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_1}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh

echo "=============== Starting sensors ==================="
create_tap_interface "${BORDER_ROUTER_NODE}" "${TAP_INTERFACE}" "${BORDER_ROUTER_IP}"
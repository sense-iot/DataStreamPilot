#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh
source /opt/riot.source

export ARCH=iotlab-m3

EXPERIMENT_NAME="mini-project-2-group-12-$SENSE_SITE"
M3_NODE_COUNT=5
A8_NODE_COUNT=0
EXPERIMENT_ID=0

# if ! is_experiment_running "${EXPERIMENT_NAME}"; then
#     echo "DataStreamPilot: submitting a new experiment"
#     # experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d ${EXPERIMENT_TIME} -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE} -l $A8_NODE_COUNT,archi=a8:at86rf231+site=${SENSE_SITE})
#     experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d ${EXPERIMENT_TIME} -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE})
#     EXPERIMENT_ID=$(echo $experiment_out | jq '.id')
#     wait_for_job "${EXPERIMENT_ID}"
# else
#     EXPERIMENT_ID=$(get_running_experiment_id "${EXPERIMENT_NAME}")
#     echo "DataStreamPilot: An experiment with the name '${EXPERIMENT_NAME}' is already running on '${EXPERIMENT_ID}'."
#     wait_for_job "${EXPERIMENT_ID}"
# fi

# write_experiment_id "$EXPERIMENT_ID"
# nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
# extract_and_categorize_nodes "$nodes_list"

# if [ ${#m3_nodes[@]} -lt ${M3_NODE_COUNT} ]; then
#     echo "DataStreamPilot: [Error] Not enough m3 nodes."
#     exit 1
# fi
# assign m3 nodes
# export BORDER_ROUTER_NODE=${m3_nodes[1]}
# export COMPUTE_ENGINE_NODE_1=${m3_nodes[2]}
# export COMPUTE_ENGINE_NODE_2=${m3_nodes[3]}
# export COMPUTE_ENGINE_NODE_3=${m3_nodes[4]}

if [ "$SENSE_SITE" = "grenoble" ]; then
    export BORDER_ROUTER_NODE=219
    export COMPUTE_ENGINE_NODE_1=220
    export COMPUTE_ENGINE_NODE_2=221
    export COMPUTE_ENGINE_NODE_3=222
elif [ "$SENSE_SITE" = "saclay" ]; then
    export BORDER_ROUTER_NODE=5
    export COMPUTE_ENGINE_NODE_1=7
    export COMPUTE_ENGINE_NODE_2=8
    export COMPUTE_ENGINE_NODE_3=9
elif [ "$SENSE_SITE" = "strasbourg" ]; then
    export BORDER_ROUTER_NODE=13
    export COMPUTE_ENGINE_NODE_1=14
    export COMPUTE_ENGINE_NODE_2=15
    export COMPUTE_ENGINE_NODE_3=16
else
    echo "Invalid SENSE_SITE value. Please set to 'grenoble', 'saclay' or 'strasbourg'."
fi

# export COMPUTE_ENGINE_NODE_1=${a8_nodes[0]}
# export COMPUTE_ENGINE_NODE_2=${a8_nodes[1]}
# export COMPUTE_ENGINE_NODE_3=${a8_nodes[2]}

write_and_print_variable "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_1" "$COMPUTE_ENGINE_NODE_1" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_2" "$COMPUTE_ENGINE_NODE_2" "m3"
write_and_print_variable "COMPUTE_ENGINE_NODE_3" "$COMPUTE_ENGINE_NODE_3" "m3"

# iotlab-experiment stop -i ${EXPERIMENT_ID}

echo "DataStreamPilot: I am sleeping for nodes to start..."
sleep 5

export NODE_CHANNEL=${DEFAULT_CHANNEL}
echo "================ Border Router and Broker node =========================="
echo "========= starting gnrc_border_router node ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh

echo "=============== Starting Compute Engine ==================="
export SENSOR_ID=1
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_1}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh

export SENSOR_ID=2
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_2}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh

export SENSOR_ID=3
export COMPUTE_ENGINE_NODE=${COMPUTE_ENGINE_NODE_3}
source ${SENSE_SCRIPTS_HOME}/compute_engine.sh
echo "=============== Starting sensors ==================="
create_tap_interface "${BORDER_ROUTER_NODE}" "${TAP_INTERFACE}" "${BORDER_ROUTER_IP}"
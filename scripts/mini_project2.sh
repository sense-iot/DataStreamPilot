#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=8
A8_NODE_COUNT=1
EXPERIMENT_ID=0

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStereamPilot: submitting a new experiment"
    experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d ${EXPERIMENT_TIME} -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE} -l $A8_NODE_COUNT,archi=a8:at86rf231+site=${SENSE_SITE})
    EXPERIMENT_ID=$(echo $experiment_out | jq '.id')
    wait_for_job "${EXPERIMENT_ID}"
    # iotlab-ssh --verbose wait-for-boot
else
    EXPERIMENT_ID=$(get_running_experiment_id "${EXPERIMENT_NAME}")
    echo "DataStereamPilot: An experiment with the name '${EXPERIMENT_NAME}' is already running on '${EXPERIMENT_ID}'."
    wait_for_job "${EXPERIMENT_ID}"
fi

write_experiment_id "$EXPERIMENT_ID"
nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
extract_and_categorize_nodes "$nodes_list"

if [ ${#m3_nodes[@]} -lt ${M3_NODE_COUNT} ]; then
    echo "DataStereamPilot: [Error] Not enough m3 nodes."
    exit 1
fi

# assign a8 nodes
export GNRC_NETWORKING_NODE=${a8_nodes[0]}

# assign m3 nodes
export BORDER_ROUTER_NODE=${m3_nodes[0]}
export DENOISER_NODE=${m3_nodes[1]}
export MQTT_CLIENT_NODE_1=${m3_nodes[2]}
export MQTT_CLIENT_NODE_2=${m3_nodes[3]}
export MQTT_CLIENT_NODE_3=${m3_nodes[4]}
export BROKER_DISCOVERY_NODE=${m3_nodes[5]}
export COMPUTER_ENGINE_NODE=${m3_nodes[6]}
export COAP_SERVER_NODE=${m3_nodes[7]}

write_and_print_variable "GNRC_NETWORKING_NODE" "$GNRC_NETWORKING_NODE" "a8"

write_and_print_variable "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE" "m3"
write_and_print_variable "DENOISER_NODE" "$DENOISER_NODE" "m3"
write_and_print_variable "MQTT_CLIENT_NODE_1" "$MQTT_CLIENT_NODE_1" "m3"
write_and_print_variable "MQTT_CLIENT_NODE_2" "$MQTT_CLIENT_NODE_2" "m3"
write_and_print_variable "MQTT_CLIENT_NODE_3" "$MQTT_CLIENT_NODE_3" "m3"
write_and_print_variable "BROKER_DISCOVERY_NODE" "$BROKER_DISCOVERY_NODE" "m3"
write_and_print_variable "COMPUTER_ENGINE_NODE" "$COMPUTER_ENGINE_NODE" "m3"
write_and_print_variable "COAP_SERVER_NODE" "$COAP_SERVER_NODE" "m3"

echo "DataStereamPilot: I am sleeping for nodes to start..."
sleep 5

echo "================ Border Router and Broker node =========================="
echo "========= starting gnrc_border_router node ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh

echo "========= starting gnrc_networking node to flash broker ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh
sleep 4
source ${SENSE_SCRIPTS_HOME}/mqtt_broker_setup.sh
export BROKER_IP=$(extract_global_ipv6)
PREV_BROKER_IP=$(read_variable_from_file "PREV_BROKER_IP")
BROKER_DETAILS_FILE=~/shared/mqtt_broker_details.txt
if [ ! -f "$BROKER_DETAILS_FILE" ]; then
    error_message="DataStereamPilot: ERROR: Broker failed"
    # Displaying the Error Message in a Box
    echo "****************************************************"
    echo "*                                                  *"
    printf "* %-36s*\n" "$error_message"
    echo "*                                                  *"
    echo "****************************************************"
    exit
fi

echo "=============== Starting Denoiser ==================="

export DENOISER_NODE=${DENOISER_NODE}
export EMCUTE_ID="DENOISER"
source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn.sh


# source ${SENSE_SCRIPTS_HOME}/coap_server.sh

echo "=============== Starting sensors ==================="

my_arch=iotlab-m3

echo "======== client 1 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_1}
export EMCUTE_ID="s1"
export CLIENT_TOPIC="s1"
export NODE_CHANNEL=${DEFAULT_CHANNEL}
# setup_and_check_sensor "$my_arch"
source ${SENSE_SCRIPTS_HOME}/paho_mqtt_client.sh.sh

export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_2}
export EMCUTE_ID="s2"
export CLIENT_TOPIC="s2"
# setup_and_check_sensor "$my_arch"
source ${SENSE_SCRIPTS_HOME}/paho_mqtt_client.sh.sh

export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_3}
export EMCUTE_ID="s3"
export CLIENT_TOPIC="s3"
# setup_and_check_sensor "$my_arch"
source ${SENSE_SCRIPTS_HOME}/paho_mqtt_client.sh.sh

echo "======================================================== $ARCH"
# source ${SENSE_SCRIPTS_HOME}/sensor-connected.sh
echo "======================================================== $ARCH"

export PREV_BROKER_IP=${BROKER_IP}
write_variable_to_file "PREV_BROKER_IP" "$PREV_BROKER_IP"

# source ${SENSE_SCRIPTS_HOME}/gnrc_border_router_a8.sh

create_tap_interface "${BORDER_ROUTER_NODE}" "${TAP_INTERFACE}" "${BORDER_ROUTER_IP}"
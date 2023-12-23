#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=7
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

write_variable_to_file "GNRC_NETWORKING_NODE" "$GNRC_NETWORKING_NODE"
write_variable_to_file "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE"
write_variable_to_file "DENOISER_NODE" "$DENOISER_NODE"
write_variable_to_file "MQTT_CLIENT_NODE_1" "$MQTT_CLIENT_NODE_1"
write_variable_to_file "MQTT_CLIENT_NODE_2" "$MQTT_CLIENT_NODE_2"
write_variable_to_file "MQTT_CLIENT_NODE_3" "$MQTT_CLIENT_NODE_3"
write_variable_to_file "BROKER_DISCOVERY_NODE" "$BROKER_DISCOVERY_NODE"
write_variable_to_file "COMPUTER_ENGINE_NODE" "$COMPUTER_ENGINE_NODE"

printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"

printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: DENOISER_NODE:" "m3 - $DENOISER_NODE"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_1:" "m3 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_2:" "m3 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_3:" "m3 - $MQTT_CLIENT_NODE_3"
printf "%-50s %s\n" "DataStereamPilot: BROKER_DISCOVERY_NODE:" "m3 - $BROKER_DISCOVERY_NODE"
printf "%-50s %s\n" "DataStereamPilot: COMPUTER_ENGINE_NODE:" "m3 - $COMPUTER_ENGINE_NODE"

echo "DataStereamPilot: I am sleeping for nodes to start..."
sleep 5

echo "================ Border Router and Broker node =========================="
echo "========= starting gnrc_border_router node ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh

echo "========= starting gnrc_networking node to flash broker ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh
sleep 1
echo "========= starting broker setup ========="
source ${SENSE_SCRIPTS_HOME}/mqtt_broker_setup.sh
export BROKER_IP=$(extract_global_ipv6)
export BROKER_IP_2=$(extract_global_ipv6)
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

export EMCUTE_ID="DENOISER"
export DENOISER_NODE=${DENOISER_NODE}
export EMCUTE_ID="DENOISER"
source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn.sh

echo "=============== Starting sensors ==================="

my_arch=iotlab-m3

echo "======== client 1 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_1}
export EMCUTE_ID="s1"
export CLIENT_TOPIC="s1"
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_1.elf
setup_and_check_sensor "${MQTT_CLIENT_NODE_1}" "${EMCUTE_ID}" "${CLIENT_TOPIC}" "${NODE_CHANNEL}" \
"${file_to_check}" "$PREV_BROKER_IP" "$BROKER_IP" "$my_arch"

echo "======== client 2 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_2}
export EMCUTE_ID="s2"
export CLIENT_TOPIC="s2"
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_2.elf
setup_and_check_sensor "${MQTT_CLIENT_NODE_2}" "${EMCUTE_ID}" "${CLIENT_TOPIC}" "${NODE_CHANNEL}" \
"${file_to_check}" "$PREV_BROKER_IP" "$BROKER_IP" "$my_arch"

# echo "======== client 3 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_3}
export EMCUTE_ID="s3"
export CLIENT_TOPIC="s3"
export NODE_CHANNEL=${DEFAULT_CHANNEL}
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_3.elf
setup_and_check_sensor "${MQTT_CLIENT_NODE_3}" "${EMCUTE_ID}" "${CLIENT_TOPIC}" "${NODE_CHANNEL}" \
"${file_to_check}" "$PREV_BROKER_IP" "$BROKER_IP" "$my_arch"

echo "======================================================== $ARCH"
# source ${SENSE_SCRIPTS_HOME}/sensor-connected.sh
echo "======================================================== $ARCH"

export PREV_BROKER_IP=${BROKER_IP}
write_variable_to_file "PREV_BROKER_IP" "$PREV_BROKER_IP"

# source ${SENSE_SCRIPTS_HOME}/gnrc_border_router_a8.sh

create_tap_interface "${BORDER_ROUTER_NODE}" "${TAP_INTERFACE}" "${BORDER_ROUTER_IP}"
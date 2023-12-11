#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=2
A8_NODE_COUNT=2
EXPERIMENT_ID=0;

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStereamPilot: submitting a new experiment"
    experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d 120 -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE} -l $A8_NODE_COUNT,archi=a8:at86rf231+site=${SENSE_SITE})
    EXPERIMENT_ID=$(echo $experiment_out | jq '.id')
    iotlab-ssh --verbose wait-for-boot
    wait_for_job "${EXPERIMENT_ID}"
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

export MQTT_CLIENT_NODE=${a8_nodes[0]}
export GNRC_NETWORKING_NODE=${a8_nodes[1]}
export BORDER_ROUTER_NODE=${m3_nodes[0]}
export SENSOR_CONNECTED_NODE=${m3_nodes[1]}

write_variable_to_file "MQTT_CLIENT_NODE" "$MQTT_CLIENT_NODE"
write_variable_to_file "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE"
write_variable_to_file "GNRC_NETWORKING_NODE" "$GNRC_NETWORKING_NODE"
write_variable_to_file "SENSOR_CONNECTED_NODE" "$SENSOR_CONNECTED_NODE"

printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE:" "a8 - $MQTT_CLIENT_NODE"
printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: SENSOR_CONNECTED_NODE:" "m3 - $SENSOR_CONNECTED_NODE"

# printf "%-25s %s\n" "COAP_SERVER_NODE:" "$COAP_SERVER_NODE"
# printf "%-25s %s\n" "SENSOR_CONNECTED_NODE:" "$SENSOR_CONNECTED_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_NODE:" "$COAP_CLIENT_NODE"
# printf "%-25s %s\n" "SENSOR_NODE:" "$SENSOR_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_TEST_NODE:" "$COAP_CLIENT_TEST_NODE"
# printf "%-25s %s\n" "HELLO_NODE:" "$HELLO_NODE"
# printf "%-25s %s\n" "SITE:" "$SENSE_SITE"

source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh
source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh

#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=2
A8_NODE_COUNT=5
EXPERIMENT_ID=0

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStereamPilot: submitting a new experiment"
    experiment_out=$(iotlab-experiment submit -n ${EXPERIMENT_NAME} -d ${EXPERIMENT_TIME} -l $M3_NODE_COUNT,archi=m3:at86rf231+site=${SENSE_SITE} -l $A8_NODE_COUNT,archi=a8:at86rf231+site=${SENSE_SITE})
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

export GNRC_NETWORKING_NODE=${a8_nodes[0]}
# export MQTT_CLIENT_NODE=${a8_nodes[1]}


export BORDER_ROUTER_NODE=${m3_nodes[0]}

export SENSOR_CONNECTED_NODE=${m3_nodes[1]}

export MQTT_CLIENT_NODE_1=${a8_nodes[1]}
export MQTT_CLIENT_NODE_2=${a8_nodes[2]}
export MQTT_CLIENT_NODE_3=${a8_nodes[3]}

write_variable_to_file "MQTT_CLIENT_NODE" "$MQTT_CLIENT_NODE"
write_variable_to_file "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE"
write_variable_to_file "GNRC_NETWORKING_NODE" "$GNRC_NETWORKING_NODE"
write_variable_to_file "SENSOR_CONNECTED_NODE" "$SENSOR_CONNECTED_NODE"
write_variable_to_file "MQTT_CLIENT_NODE_1" "$MQTT_CLIENT_NODE_1"
write_variable_to_file "MQTT_CLIENT_NODE_2" "$MQTT_CLIENT_NODE_2"
write_variable_to_file "MQTT_CLIENT_NODE_3" "$MQTT_CLIENT_NODE_3"

printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_1:" "a8 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_2:" "a8 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_3:" "a8 - $MQTT_CLIENT_NODE_3"

printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: SENSOR_CONNECTED_NODE:" "m3 - $SENSOR_CONNECTED_NODE"


# printf "%-25s %s\n" "COAP_SERVER_NODE:" "$COAP_SERVER_NODE"
# printf "%-25s %s\n" "SENSOR_CONNECTED_NODE:" "$SENSOR_CONNECTED_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_NODE:" "$COAP_CLIENT_NODE"
# printf "%-25s %s\n" "SENSOR_NODE:" "$SENSOR_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_TEST_NODE:" "$COAP_CLIENT_TEST_NODE"
# printf "%-25s %s\n" "HELLO_NODE:" "$HELLO_NODE"
# printf "%-25s %s\n" "SITE:" "$SENSE_SITE"

echo "================ Border Router ======================"
# source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh

echo "============== Broker setup ======================="
# source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh
# source ${SENSE_SCRIPTS_HOME}/mqtt_broker_setup.sh
export BROKER_IP=$(extract_global_ipv6)
PREV_BROKER_IP=$(read_variable_from_file "PREV_BROKER_IP")

echo "=============== Starting sensors ==================="

echo "======== client 1 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_1}
export EMCUTE_ID="SENSOR_1"
export CLIENT_TOPIC="sens1_temperature"
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_1.elf

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
    source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
else
    echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
    if [ ! -f "$file_to_check" ]; then
        source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
        echo "ELF NOT FOUND"
    else
        echo "File exists: $file_to_check"
        ELF_FILE=$file_to_check
        # flash_elf ${ELF_FILE} ${MQTT_CLIENT_NODE}
        echo "flashing sensor 1 from root script"
        ssh -oStrictHostKeyChecking=accept-new root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
    fi
fi

echo "======== client 2 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_2}
export EMCUTE_ID="SENSOR_2"
export CLIENT_TOPIC="sens2_temperature"
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_2.elf
if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
    source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
else
    echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
    
    if [ ! -f "$file_to_check" ]; then
        source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
        echo "ELF NOT FOUND"
    else
        echo "File exists: $file_to_check"
        ELF_FILE=$file_to_check
        # flash_elf ${ELF_FILE} ${MQTT_CLIENT_NODE}
        echo "flashing sensor 2 from root script"
        ssh -oStrictHostKeyChecking=accept-new root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
    fi
fi

# echo "======== client 3 sensor ======================="
export MQTT_CLIENT_NODE=${MQTT_CLIENT_NODE_3}
export EMCUTE_ID="SENSOR_3"
export CLIENT_TOPIC="sens3_temperature"
file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_SENSOR_3.elf

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
    source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
else
    echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
    if [ ! -f "$file_to_check" ]; then
        source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
        echo "ELF NOT FOUND"
    else
        echo "File exists: $file_to_check"
        ELF_FILE=$file_to_check
        # flash_elf ${ELF_FILE} ${MQTT_CLIENT_NODE}
        echo "flashing sensor 3 from root script"
        ssh -oStrictHostKeyChecking=accept-new root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
    fi
fi

echo "======================================================== $ARCH"
# source ${SENSE_SCRIPTS_HOME}/sensor-connected.sh
echo "======================================================== $ARCH"

export PREV_BROKER_IP=${BROKER_IP}
write_variable_to_file "PREV_BROKER_IP" "$PREV_BROKER_IP"

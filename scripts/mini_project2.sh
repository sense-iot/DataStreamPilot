#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
M3_NODE_COUNT=6
A8_NODE_COUNT=2
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
export DENOISER_NODE=${a8_nodes[1]}

# assign m3 nodes
export BORDER_ROUTER_NODE=${m3_nodes[0]}
export SENSOR_CONNECTED_NODE=${m3_nodes[1]}
export DENOISER_NODE_TEST=${m3_nodes[2]}

export MQTT_CLIENT_NODE_1=${m3_nodes[3]}
export MQTT_CLIENT_NODE_2=${m3_nodes[4]}
export MQTT_CLIENT_NODE_3=${m3_nodes[5]}

write_variable_to_file "MQTT_CLIENT_NODE" "$MQTT_CLIENT_NODE"
write_variable_to_file "BORDER_ROUTER_NODE" "$BORDER_ROUTER_NODE"
write_variable_to_file "GNRC_NETWORKING_NODE" "$GNRC_NETWORKING_NODE"
write_variable_to_file "SENSOR_CONNECTED_NODE" "$SENSOR_CONNECTED_NODE"
write_variable_to_file "MQTT_CLIENT_NODE_1" "$MQTT_CLIENT_NODE_1"
write_variable_to_file "MQTT_CLIENT_NODE_2" "$MQTT_CLIENT_NODE_2"
write_variable_to_file "MQTT_CLIENT_NODE_3" "$MQTT_CLIENT_NODE_3"
write_variable_to_file "DENOISER_NODE_TEST" "$DENOISER_NODE_TEST"
write_variable_to_file "DENOISER_NODE" "$DENOISER_NODE"

printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStereamPilot: DENOISER_NODE:" "a8 - $DENOISER_NODE"

printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: SENSOR_CONNECTED_NODE:" "m3 - $SENSOR_CONNECTED_NODE"
printf "%-50s %s\n" "DataStereamPilot: DENOISER_NODE_TEST:" "m3 - $DENOISER_NODE_TEST"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_1:" "m3 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_2:" "m3 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_3:" "m3 - $MQTT_CLIENT_NODE_3"

# printf "%-25s %s\n" "COAP_SERVER_NODE:" "$COAP_SERVER_NODE"
# printf "%-25s %s\n" "SENSOR_CONNECTED_NODE:" "$SENSOR_CONNECTED_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_NODE:" "$COAP_CLIENT_NODE"
# printf "%-25s %s\n" "SENSOR_NODE:" "$SENSOR_NODE"
# printf "%-25s %s\n" "COAP_CLIENT_TEST_NODE:" "$COAP_CLIENT_TEST_NODE"
# printf "%-25s %s\n" "HELLO_NODE:" "$HELLO_NODE"
# printf "%-25s %s\n" "SITE:" "$SENSE_SITE"
echo "I am sleeping for nodes to start..."
sleep 5

echo "================ Border Router and Broker node =========================="
echo "========= starting gnrc_border_router node ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh
create_tap_interface "${BORDER_ROUTER_NODE}" &
sleep 1
echo "========= starting gnrc_networking node to flash broker ========="
source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh
sleep 1
echo "========= starting broker setup ========="
source ${SENSE_SCRIPTS_HOME}/mqtt_broker_setup.sh
export BROKER_IP=$(extract_global_ipv6)
PREV_BROKER_IP=$(read_variable_from_file "PREV_BROKER_IP")

BROKER_DETAILS_FILE=~/shared/mqtt_broker_details.txt
if [ ! -f "$BROKER_DETAILS_FILE" ]; then
    error_message="ERROR: Broker failed"
    # Displaying the Error Message in a Box
    echo "****************************************************"
    echo "*                                                  *"
    printf "* %-36s*\n" "$error_message"
    echo "*                                                  *"
    echo "****************************************************"
    exit
fi

echo "======================================================"

export EMCUTE_ID="DENOISER"
export DENOISER_NODE_TEST=${DENOISER_NODE_TEST}
source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn.sh

echo "=============== Starting Denoiser ==================="

export DENOISER_NODE=${DENOISER_NODE}
export EMCUTE_ID="DENOISER"
# export CLIENT_TOPIC1="sens1_temperature"
# export CLIENT_TOPIC2="sens2_temperature"
# export CLIENT_TOPIC3="sens3_temperature"
# export DENOISE_TOPIC="denoise_temperature"

file_to_check=${SENSE_HOME}/release/denoiser.elf

if [ "$PREV_BROKER_IP" != "$BROKER_IP" ]; then
    echo "DataStereamPilot: The broker IP has changed ${BROKER_IP}."
    source ${SENSE_SCRIPTS_HOME}/denoiser.sh
else
    echo "DataStereamPilot: The broker IP has not changed ${BROKER_IP}."
    if [ ! -f "$file_to_check" ]; then
        source ${SENSE_SCRIPTS_HOME}/denoiser.sh
        echo "ELF NOT FOUND"
    else
        echo "File exists: $file_to_check"
        ELF_FILE=$file_to_check
        # flash_elf ${ELF_FILE} ${MQTT_CLIENT_NODE}
        echo "flashing denoiser from root script"
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${DENOISER_NODE} 'bash -s' <${SENSE_HOME}/src/network/denoiser/ssh_denoiser.sh
    fi
fi

echo "=============== Starting sensors ==================="

# iotlab-m3, iotlab-a8-m3
my_arch=iotlab-m3

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
        echo "flashing sensor 1 from root script"

        if [ "$my_arch" = "iotlab-m3" ]; then
            cp $file_to_check ${SENSE_FIRMWARE_HOME}
            echo "Architecture is iotlab-m3."
            flash_elf $file_to_check ${MQTT_CLIENT_NODE}
        elif [ "$my_arch" = "iotlab-a8-m3" ]; then
            cp $file_to_check ~/A8/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf
            echo "Architecture is iotlab-a8-m3."
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
            echo "ssh root@node-a8-${MQTT_CLIENT_NODE}"
        else
            echo "Architecture is something else."
        fi
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
        if [ "$my_arch" = "iotlab-m3" ]; then
            cp $file_to_check ${SENSE_FIRMWARE_HOME}
            echo "Architecture is iotlab-m3."
            flash_elf $file_to_check ${MQTT_CLIENT_NODE}
        elif [ "$my_arch" = "iotlab-a8-m3" ]; then
            cp $file_to_check ~/A8/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf
            echo "Architecture is iotlab-a8-m3."
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
            echo "ssh root@node-a8-${MQTT_CLIENT_NODE}"
        else
            echo "Architecture is something else."
        fi
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
        if [ "$my_arch" = "iotlab-m3" ]; then
            cp $file_to_check ${SENSE_FIRMWARE_HOME}
            echo "Architecture is iotlab-m3."
            flash_elf $file_to_check ${MQTT_CLIENT_NODE}
        elif [ "$my_arch" = "iotlab-a8-m3" ]; then
            cp $file_to_check ~/A8/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${EMCUTE_ID}.elf
            echo "Architecture is iotlab-a8-m3."
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${MQTT_CLIENT_NODE} 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${EMCUTE_ID}.sh
            echo "ssh root@node-a8-${MQTT_CLIENT_NODE}"
        else
            echo "Architecture is something else."
        fi
    fi
fi

echo "======================================================== $ARCH"
# source ${SENSE_SCRIPTS_HOME}/sensor-connected.sh
echo "======================================================== $ARCH"

export PREV_BROKER_IP=${BROKER_IP}
write_variable_to_file "PREV_BROKER_IP" "$PREV_BROKER_IP"

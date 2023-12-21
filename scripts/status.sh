#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

EXPERIMENT_NAME="mini-project-2-group-12"
EXPERIMENT_ID=$(read_experiment_id)
echo "DataStereamPilot: Current experiment ID : ${EXPERIMENT_ID}"

if ! is_experiment_running "${EXPERIMENT_NAME}"; then
    echo "DataStereamPilot: Experiment '${EXPERIMENT_NAME}' not running"
    exit 0
fi

nodes_list=$(iotlab-experiment get -i ${EXPERIMENT_ID} -p)
extract_and_categorize_nodes "$nodes_list"

# Access and use the global arrays
echo "DataStereamPilot: a8 nodes: ${a8_nodes[@]}"
echo "DataStereamPilot: m3 nodes: ${m3_nodes[@]}"

MQTT_CLIENT_NODE_1=$(read_variable_from_file "MQTT_CLIENT_NODE_1")
MQTT_CLIENT_NODE_2=$(read_variable_from_file "MQTT_CLIENT_NODE_2")
MQTT_CLIENT_NODE_3=$(read_variable_from_file "MQTT_CLIENT_NODE_3")
BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
BORDER_ROUTER_NODE_2=$(read_variable_from_file "BORDER_ROUTER_NODE_2")
SENSOR_CONNECTED_NODE=$(read_variable_from_file "SENSOR_CONNECTED_NODE")
DENOISER_NODE=$(read_variable_from_file "DENOISER_NODE")
DENOISER_NODE_TEST=$(read_variable_from_file "DENOISER_NODE_TEST")
BORDER_ROUTER_NODE_a8=$(read_variable_from_file "BORDER_ROUTER_NODE_a8")

printf "%-50s %s\n" "DataStereamPilot: GNRC_NETWORKING_NODE:" "a8 - $GNRC_NETWORKING_NODE"
printf "%-50s %s\n" "DataStereamPilot: DENOISER_NODE:" "a8 - $DENOISER_NODE"
printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE_a8:" "a8 - $BORDER_ROUTER_NODE_a8"

printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE:" "m3 - $BORDER_ROUTER_NODE"
printf "%-50s %s\n" "DataStereamPilot: BORDER_ROUTER_NODE_2:" "m3 - $BORDER_ROUTER_NODE_2"
# printf "%-50s %s\n" "DataStereamPilot: SENSOR_CONNECTED_NODE:" "m3 - $SENSOR_CONNECTED_NODE"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_1:" "m3 - $MQTT_CLIENT_NODE_1"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_2:" "m3 - $MQTT_CLIENT_NODE_2"
printf "%-50s %s\n" "DataStereamPilot: MQTT_CLIENT_NODE_3:" "m3 - $MQTT_CLIENT_NODE_3"
printf "%-50s %s\n" "DataStereamPilot: DENOISER_NODE_TEST:" "m3 - $DENOISER_NODE_TEST"


echo " ----- M3 - A8 nodes ----- "
echo "ssh root@node-a8-${GNRC_NETWORKING_NODE}  # mqtt broker"
echo "ssh root@node-a8-${DENOISER_NODE}    # denoiser"
echo "ssh root@node-a8-${BORDER_ROUTER_NODE_a8}    # a8 border router"

echo " ----- M3 nodes ----- "
echo "nc m3-${BORDER_ROUTER_NODE} 20000         # border router"
echo "nc m3-${SENSOR_CONNECTED_NODE} 20000      # sensor connected"
echo "nc m3-${DENOISER_NODE_TEST} 20000      # DENOISER_NODE_TEST"
echo "nc m3-${MQTT_CLIENT_NODE_1} 20000   # sensor 1"
echo "nc m3-${MQTT_CLIENT_NODE_2} 20000   # sensor 2"
echo "nc m3-${MQTT_CLIENT_NODE_3} 20000   # sensor 3"


echo "Broker IP : $(extract_global_ipv6)"
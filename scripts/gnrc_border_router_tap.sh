#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

current_ethos_id=$(ps -ef | grep ethos | grep -v "grep" | grep perera | awk '{print $2}' | head -1)
if [ -z "$current_ethos_id" ]; then
    echo "No matching ethos process found."
else
    echo "Ethos process ID: $current_ethos_id"
    echo "Killing Ethos process ID $current_ethos_id"
    kill -9 $current_ethos_id
fi

BORDER_ROUTER_NODE_2=$(read_variable_from_file "BORDER_ROUTER_NODE_2")
BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
create_tap_interface "${BORDER_ROUTER_NODE}" "${TAP_INTERFACE}" "${BORDER_ROUTER_IP}"

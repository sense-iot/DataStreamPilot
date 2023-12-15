#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

BORDER_ROUTER_NODE=$(read_variable_from_file "BORDER_ROUTER_NODE")
create_tap_interface "${BORDER_ROUTER_NODE}"
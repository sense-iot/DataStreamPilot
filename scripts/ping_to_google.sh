#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  GNRC_NETWORKING_NODE=$(read_variable_from_file "GNRC_NETWORKING_NODE")
  ssh root@node-a8-${GNRC_NETWORKING_NODE} 'bash -s' <${SENSE_HOME}/src/network/gnrc_networking_a8/ping.sh
fi

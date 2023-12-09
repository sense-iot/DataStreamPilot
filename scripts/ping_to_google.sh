#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then

  source ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh
  source ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh

  echo "I am sleeping for few seconds..."
  sleep 10

  # connecting to intermediate router
  # from this node you can type help
  # ifconfig
  # and also ping google
  # ping 2001:4860:4860::8888 or 2001:4860:4860::8844
  echo ""
  echo "You are connected to m3-${GNRC_NETWORKING_NODE} node"
  echo "try to ping to google : ping 2001:4860:4860::8888"

  nc m3-${GNRC_NETWORKING_NODE} 20000
else
  echo "Please run the script in SSH fron end"
fi

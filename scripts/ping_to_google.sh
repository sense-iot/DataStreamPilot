#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME}

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
  ${SENSE_SCRIPTS_HOME}/gnrc_border_router.sh
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi

  ${SENSE_SCRIPTS_HOME}/gnrc_networking.sh
  build_status=$?
  if [ $build_status -ne 0 ]; then
    exit $build_status
  fi

  create_tap_interface "${BORDER_ROUTER_NODE}" &

  echo "I am sleeping for few seconds..."
  sleep 5

  # connecting to intermediate router
  # from this node you can type help
  # ifconfig
  # and also ping google
  # ping 2001:4860:4860::8888 or 2001:4860:4860::8844
  echo ""
  echo "You are connected to m3-${GNRC_NETWORKING_NODE} node"
  echo "try to ping to google : ping 2001:4860:4860::8888"
  nc m3-${GNRC_NETWORKING_NODE} 20000

  stop_jobs "${n_node_job_id}" "${border_router_job_id}"
fi

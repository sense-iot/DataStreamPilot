#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

if [ $ERROR_WRONG_SITE -ne 0]; then
    exit $ERROR_WRONG_SITE
fi

build_wireless_firmware_cached ${BORDER_ROUTER_HOME} ${BORDER_ROUTER_EXE_NAME}
build_status=$?
if [ $build_status -ne 0 ]; then
    exit $build_status
fi

build_wireless_firmware ${COMPUTE_ENGINE_HOME} ${COMPUTE_ENGINE_EXE_NAME}
build_status=$?
if [ $build_status -ne 0 ]; then
    exit $build_status
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
    echo "Copy firmware files to shared"
    echo "cp ${BORDER_ROUTER_HOME}/bin/${ARCH}/${BORDER_ROUTER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}"

    cp ${BORDER_ROUTER_HOME}/bin/${ARCH}/${BORDER_ROUTER_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}
    cp ${COMPUTE_ENGINE_HOME}/bin/${ARCH}/${COMPUTE_ENGINE_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

    # submit border router job and save job id
    border_router_job_id=$(submit_border_router_job "${BORDER_ROUTER_NODE}")
    compute_engine_node_job_id=$(submit_compute_node_job "${COMPUTE_ENGINE_NODE}")

    create_stopper_script $n_node_job_id $border_router_job_id $compute_engine_node_job_id

    wait_for_job "${border_router_job_id}"
    wait_for_job "${compute_engine_node_job_id}"

    create_tap_interface "${BORDER_ROUTER_NODE}" &

    echo "aiocoap-client coap://[2001:660:5307:3107:a4a9:dc28:5c45:38a9]/riot/board"
    echo "coap info"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /.well-known/core"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /riot/board"
    echo "coap get 192.168.2.135:5683 /.well-known/core"
    echo "coap get example.com:5683 /.well-known/core # with sock dns"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /temperature"

    echo "I am setting up the system......"
    sleep 10
    echo "Connecting to sensor node....."
    echo "nc m3-${COMPUTE_ENGINE_NODE} 20000"
    nc m3-${COMPUTE_ENGINE_NODE} 20000

    stop_jobs "${compute_engine_node_job_id}" "${n_node_job_id}" "${border_router_job_id}"
fi



# source setup.sh
# source ${SENSE_SCRIPTS_HOME}/setup_env.sh

# build_wireless_firmware ${COMPUTE_ENGINE_HOME} ${COMPUTE_ENGINE_EXE_NAME}
# build_status=$?
# if [ $build_status -ne 0 ]; then
#     exit $build_status
# fi

# if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
#   cp ${COMPUTE_ENGINE_HOME}/bin/${ARCH}/${COMPUTE_ENGINE_EXE_NAME}.elf ${SENSE_FIRMWARE_HOME}

#   flash_firmware ${COMPUTE_ENGINE_EXE_NAME} ${COMPUTE_ENGINE_NODE}
  
#   #create_tap_interface "${COMPUTE_ENGINE_NODE}" &
  
#   export COMPUTE_ENGINE_ROUTER_UP=1

#   echo "aiocoap-client coap://[2001:660:5307:3107:a4a9:dc28:5c45:38a9]/riot/board"
#   echo "coap info"
#   echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /.well-known/core"
#   echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /riot/board"
#   echo "coap get 192.168.2.135:5683 /.well-known/core"
#   echo "coap get example.com:5683 /.well-known/core # with sock dns"
#   echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /temperature"

#   echo "nc m3-${COMPUTE_ENGINE_NODE} 20000"
#   nc m3-${COMPUTE_ENGINE_NODE} 20000

# fi



#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh

file_to_check=${SENSE_HOME}/release/compute_engine.elf
my_arch=${ARCH}

# Check if the file exists
if [ ! -f "$file_to_check" ]; then
    build_wireless_firmware ${COMPUTE_ENGINE_HOME} ${COMPUTE_ENGINE_EXE_NAME} ${ARCH} ${NODE_CHANNEL}
    build_status=$?
    if [ $build_status -ne 0 ]; then
        exit $build_status
    fi
    ELF_FILE=${COMPUTE_ENGINE_HOME}/bin/${ARCH}/${COMPUTE_ENGINE_EXE_NAME}.elf
else
    echo "DataStreamPilot: File exists: $file_to_check"
    ELF_FILE=$file_to_check
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then
    cp $ELF_FILE ${SENSE_FIRMWARE_HOME}
    cp $ELF_FILE ${SENSE_HOME}/release/${COMPUTE_ENGINE_EXE_NAME}.elf

    echo "DataStreamPilot:Flashing new firmware for ${ARCH} node : ${COMPUTE_ENGINE_NODE}"
    flash_firmware ${COMPUTE_ENGINE_EXE_NAME} ${COMPUTE_ENGINE_NODE}

    export COMPUTE_ENGINE_ROUTER_UP=1

    echo "aiocoap-client coap://[2001:660:5307:3107:a4a9:dc28:5c45:38a9]/riot/board"
    echo "coap info"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /.well-known/core"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /riot/board"
    echo "coap get 192.168.2.135:5683 /.well-known/core"
    echo "coap get example.com:5683 /.well-known/core # with sock dns"
    echo "coap get [2001:660:5307:3107:a4a9:dc28:5c45:38a9]:5683 /temperature"

    echo "I am setting up the system......"
    #sleep 10
    echo "Connecting to compute engine node....."
    echo "nc m3-${COMPUTE_ENGINE_NODE} 20000"
    #nc m3-${COMPUTE_ENGINE_NODE} 20000
fi

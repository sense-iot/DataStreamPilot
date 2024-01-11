#!/usr/bin/env bash

source setup.sh
source ${SENSE_SCRIPTS_HOME}/setup_env.sh
source /opt/riot.source

RELEASE_FILE=${SENSE_HOME}/release/${COMPUTE_ENGINE_EXE_NAME}_${SENSOR_ID}_${SENSE_SITE}.elf
build_path=${COMPUTE_ENGINE_HOME}/bin/${ARCH}/${COMPUTE_ENGINE_EXE_NAME}.elf
my_arch=${ARCH}

# Check if the file exists
if [ ! -f "$RELEASE_FILE" ]; then
    build_wireless_firmware ${COMPUTE_ENGINE_HOME} ${COMPUTE_ENGINE_EXE_NAME} ${ARCH} ${NODE_CHANNEL}
    build_status=$?
    if [ $build_status -ne 0 ]; then
        exit $build_status
    fi
    cp $build_path $RELEASE_FILE
else
    echo "DataStreamPilot: File exists: $RELEASE_FILE"
fi

if [ -n "$IOT_LAB_FRONTEND_FQDN" ]; then

    if [ "$my_arch" = "iotlab-m3" ]; then
        echo "Flashing new firmware for ${my_arch} node : ${COMPUTE_ENGINE_NODE}"
        # flash_elf ${RELEASE_FILE} ${COMPUTE_ENGINE_NODE}

        iotlab-experiment submit -n "${COMPUTE_ENGINE_EXE_NAME}_${SENSOR_ID}" -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},m3,${COMPUTE_ENGINE_NODE},${SENSE_HOME}/release/${COMPUTE_ENGINE_EXE_NAME}_${SENSOR_ID}_${SENSE_SITE}.elf
        # nc m3-${COMPUTE_ENGINE_NODE} 20000
    elif [ "$my_arch" = "iotlab-a8-m3" ]; then
        cp $ELF_FILE ~/A8/${COMPUTE_ENGINE_EXE_NAME}_${SENSOR_ID}_a8.elf
        until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${COMPUTE_ENGINE_NODE} 'bash -s' <${SENSE_HOME}/src/compute_engine/compute_engine_SENSOR_${SENSOR_ID}.sh; do
            echo "DataStreamPilot: ------------------------------------------"
            echo "DataStreamPilot: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-${COMPUTE_ENGINE_NODE} 'bash -s' <${SENSE_HOME}/src/compute_engine/compute_engine_SENSOR_${SENSOR_ID}.sh"
            echo "DataStreamPilot: Error: ssh failed to COMPUTE_ENGINE. Retrying...!"
            echo "DataStreamPilot: ------------------------------------------"
            sleep 10
        done

        echo "ssh root@node-a8-${COMPUTE_ENGINE_NODE}"
    else
        echo "Architecture is something else."
    fi

    echo "nc m3-${COMPUTE_ENGINE_NODE} 20000"
fi

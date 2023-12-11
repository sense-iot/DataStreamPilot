#!/usr/bin/env bash

# script has already run once for the current shell

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    if [ -n "$SENSE_SETUP_ENV_UP" ]; then
        return 0
    fi
fi

source ${SENSE_SCRIPTS_HOME}/common_functions.sh
# grenoble, paris, lille, saclay, strasbourg
export SENSE_SITE=grenoble

printf "%-50s %s\n" "DataStereamPilot: SENSE_SITE:" "$SENSE_SITE"

# Get the current hostname
current_hostname=$(hostname)

# Compare the current hostname with the expected one
if [ "$current_hostname" != "$SENSE_SITE" ]; then
    error_message="ERROR: You are on site '$current_hostname', not on '$SENSE_SITE'"
    # Displaying the Error Message in a Box
    echo "****************************************************"
    echo "*                                                  *"
    printf "* %-36s*\n" "$error_message"
    printf "* %-49s*\n" $0
    printf "* %s %-37s*\n" "SENSE_SITE:" "$SENSE_SITE"
    echo "* Change SENSE_SITE variable in setup_env.sh       *"
    echo "*                                                  *"
    echo "****************************************************"
    export ERROR_WRONG_SITE=1
    exit $ERROR_WRONG_SITE
fi

# comment this out in production
if [ -z "$COAP_SERVER_IP" ]; then
    # If not set, then export it with the specified value
    export COAP_SERVER_IP="[2001:660:5307:3108:ec1b:fa40:6a45:de4d]:5683"
fi
export COAP_SERVER_IP_ONLY=$(extract_ip "$COAP_SERVER_IP")

# Site		    subnets	from			        to
# Grenoble	    128	    2001:660:5307:3100::/64	2001:660:5307:317f::/64
# Lille		    128	    2001:660:4403:0480::/64	2001:660:4403:04ff::/64
# Paris		    128	    2001:660:330f:a280::/64	2001:660:330f:a2ff::/64
# Saclay	    64	    2001:660:3207:04c0::/64	2001:660:3207:04ff::/64
# Strasbourg	32	    2001:660:4701:f0a0::/64	2001:660:4701:f0bf::/64

# https://www.iot-lab.info/legacy/tutorials/understand-ipv6-subnetting-on-the-fit-iot-lab-testbed/index.html

if [ "$SENSE_SITE" = "grenoble" ]; then
    # 2001:660:5307:3100::/64	2001:660:5307:317f::/64
    export BORDER_ROUTER_IP=2001:660:5307:313f::1/64
elif [ "$SENSE_SITE" = "paris" ]; then
    # 2001:660:330f:a280::/64   2001:660:330f:a2ff::/64
    export BORDER_ROUTER_IP=2001:660:330f:a293::1/64
elif [ "$SENSE_SITE" = "lille" ]; then
    # 2001:660:4403:0480::/64	2001:660:4403:04ff::/64
    export BORDER_ROUTER_IP=2001:660:4403:0493::1/64
elif [ "$SENSE_SITE" = "saclay" ]; then
    # 2001:660:3207:04c0::/64	2001:660:3207:04ff::/64
    export BORDER_ROUTER_IP=2001:660:3207:04de::1/64
elif [ "$SENSE_SITE" = "strasbourg" ]; then
    # 2001:660:4701:f0a0::/64	2001:660:4701:f0bf::/64
    export BORDER_ROUTER_IP=2001:660:4701:f0af::1/64
else
    echo "Invalid SENSE_SITE value. Please set to 'grenoble' or 'paris'."
fi

export ARCH=iotlab-m3

# values are from 11-26
export DEFAULT_CHANNEL=22
#export DEFAULT_CHANNEL=23 - dilan
#export DEFAULT_CHANNEL=24 - waas
#export DEFAULT_CHANNEL=25 - rukshan

export ETHOS_BAUDRATE=500000
export TAP_INTERFACE=tap7
# export TAP_INTERFACE=tap4 - dilan
# export TAP_INTERFACE=tap5 - waas
# export TAP_INTERFACE=tap6 - rukshan

# this is seconds
export JOB_WAIT_TIMEOUT=120
export EXPERIMENT_TIME=20

export BORDER_ROUTER_FOLDER_NAME=gnrc_border_router
export BORDER_ROUTER_EXE_NAME=${BORDER_ROUTER_FOLDER_NAME}
export BORDER_ROUTER_HOME=${SENSE_HOME}/src/network/${BORDER_ROUTER_FOLDER_NAME}

export GNRC_NETWORKING_FOLDER_NAME=gnrc_networking
export GNRC_NETWORKING_EXE_NAME=${GNRC_NETWORKING_FOLDER_NAME}
export GNRC_NETWORKING_HOME=${SENSE_HOME}/src/network/${GNRC_NETWORKING_FOLDER_NAME}

export COAP_SERVER_FOLDER_NAME=nanocoap_server
export COAP_SERVER_EXE_NAME=${COAP_SERVER_FOLDER_NAME}
export COAP_SERVER_HOME=${SENSE_HOME}/src/network/${COAP_SERVER_FOLDER_NAME}

export COAP_CLIENT_FOLDER_NAME=gcoap
export COAP_CLIENT_EXE_NAME=${COAP_CLIENT_FOLDER_NAME}
export COAP_CLIENT_HOME=${SENSE_HOME}/src/network/${COAP_CLIENT_FOLDER_NAME}

export COAP_CLIENT_TEST_FOLDER_NAME=gcoap_test
export COAP_CLIENT_TEST_EXE_NAME=${COAP_CLIENT_TEST_FOLDER_NAME}
export COAP_CLIENT_TEST_HOME=${SENSE_HOME}/src/network/${COAP_CLIENT_TEST_FOLDER_NAME}

export SENSOR_READ_FOLDER_NAME=sensor-m3-temperature
export SENSOR_READ_EXE_NAME=${SENSOR_READ_FOLDER_NAME}
export SENSOR_READ_HOME=${SENSE_HOME}/src/sensor/${SENSOR_READ_FOLDER_NAME}

export SENSOR_CONNECTED_FOLDER_NAME=sensor-connected
export SENSOR_CONNECTED_EXE_NAME=${SENSOR_CONNECTED_FOLDER_NAME}
export SENSOR_CONNECTED_HOME=${SENSE_HOME}/src/sensor/${SENSOR_CONNECTED_FOLDER_NAME}

export SENSOR_2_CONNECTED_FOLDER_NAME=sensor2
export SENSOR_2_CONNECTED_EXE_NAME=${SENSOR_2_CONNECTED_FOLDER_NAME}
export SENSOR_2_CONNECTED_HOME=${SENSE_HOME}/src/sensor/${SENSOR_2_CONNECTED_FOLDER_NAME}

#SENSE_SCRIPTS_HOME="${SENSE_HOME}/${SCRIPTS}"
#SENSE_STOPPERS_HOME="${SENSE_SCRIPTS_HOME}/stoppers"
#SENSE_FIRMWARE_HOME="${HOME}/bin"

export SENSE_SETUP_ENV_UP=1

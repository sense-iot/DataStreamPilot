#!/usr/bin/env bash

export JOB_WAIT_TIMEOUT=150
export EXPERIMENT_TIME=300

# grenoble, paris, lille, saclay, strasbourg
export SENSE_SITE=grenoble
printf "%-50s %s\n" "DataStreamPilot: SENSE_SITE:" "$SENSE_SITE"

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

source ${SENSE_SCRIPTS_HOME}/common_functions.sh

# comment this out in production
if [ -z "$COAP_SERVER_IP" ]; then
    # If not set, then export it with the specified value
    export COAP_SERVER_IP="[2600:1f16:15a8:30b:2e54:6b9b:742c:31fe]:5683"
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
    export BORDER_ROUTER_IP_2=2001:660:5307:313a::1/64
elif [ "$SENSE_SITE" = "paris" ]; then
    # 2001:660:330f:a280::/64   2001:660:330f:a2ff::/64
    export BORDER_ROUTER_IP=2001:660:330f:a293::1/64
    export BORDER_ROUTER_IP_2=2001:660:330f:a29f::1/64
elif [ "$SENSE_SITE" = "lille" ]; then
    # 2001:660:4403:0480::/64	2001:660:4403:04ff::/64
    export BORDER_ROUTER_IP=2001:660:4403:0493::1/64
    export BORDER_ROUTER_IP_2=2001:660:4403:049f::1/64
elif [ "$SENSE_SITE" = "saclay" ]; then
    # 2001:660:3207:04c0::/64	2001:660:3207:04ff::/64
    export BORDER_ROUTER_IP=2001:660:3207:04de::1/64
    export BORDER_ROUTER_IP_2=2001:660:3207:04df::1/64
elif [ "$SENSE_SITE" = "strasbourg" ]; then
    # 2a07:2e40:fffe:00e0::/64	2a07:2e40:fffe:00ff::/64
    export BORDER_ROUTER_IP=2a07:2e40:fffe:00fe::1/64
    export BORDER_ROUTER_IP_2=2a07:2e40:fffe:00fa::1/64
else
    echo "Invalid SENSE_SITE value. Please set to 'grenoble' or 'paris'."
fi

# values are from 11-26
export DEFAULT_CHANNEL=22
export PANID=0xff0c

export ETHOS_BAUDRATE=500000
export TAP_INTERFACE=tap23

export BORDER_ROUTER_FOLDER_NAME=gnrc_border_router
export BORDER_ROUTER_EXE_NAME=${BORDER_ROUTER_FOLDER_NAME}
export BORDER_ROUTER_HOME=${SENSE_HOME}/src/network/${BORDER_ROUTER_FOLDER_NAME}

export COMPUTE_ENGINE_FOLDER_NAME=compute_engine
export COMPUTE_ENGINE_EXE_NAME=${COMPUTE_ENGINE_FOLDER_NAME}
export COMPUTE_ENGINE_HOME=${SENSE_HOME}/src/${COMPUTE_ENGINE_FOLDER_NAME}


# export GNRC_NETWORKING_FOLDER_NAME=gnrc_networking
# export GNRC_NETWORKING_EXE_NAME=${GNRC_NETWORKING_FOLDER_NAME}
# export GNRC_NETWORKING_HOME=${SENSE_HOME}/src/network/${GNRC_NETWORKING_FOLDER_NAME}

# export EMCUTE_MQTSSN_FOLDER_NAME=emcute_mqttsn
# export EMCUTE_MQTSSN_EXE_NAME=${EMCUTE_MQTSSN_FOLDER_NAME}
# export EMCUTE_MQTSSN_HOME=${SENSE_HOME}/src/network/${EMCUTE_MQTSSN_FOLDER_NAME}

# export EMCUTE_MQTSSN_CLIENT_FOLDER_NAME=emcute_mqttsn_client
# export EMCUTE_MQTSSN_CLIENT_EXE_NAME=${EMCUTE_MQTSSN_CLIENT_FOLDER_NAME}
# export EMCUTE_MQTSSN_CLIENT_HOME=${SENSE_HOME}/src/network/${EMCUTE_MQTSSN_CLIENT_FOLDER_NAME}

# export DENOISER_FOLDER_NAME=denoiser
# export DENOISER_EXE_NAME=${DENOISER_FOLDER_NAME}
# export DENOISER_HOME=${SENSE_HOME}/src/network/${DENOISER_FOLDER_NAME}

# export ASYMCUTE_MQTTSN_FOLDER_NAME=asymcute_mqttsn
# export ASYMCUTE_MQTTSN_EXE_NAME=${ASYMCUTE_MQTTSN_FOLDER_NAME}
# export ASYMCUTE_MQTTSN_HOME=${SENSE_HOME}/src/network/${ASYMCUTE_MQTTSN_FOLDER_NAME}

# export PAHO_MQTT_FOLDER_NAME=paho-mqtt
# export PAHO_MQTT_EXE_NAME=${PAHO_MQTT_FOLDER_NAME}
# export PAHO_MQTT_HOME=${SENSE_HOME}/src/network/${PAHO_MQTT_FOLDER_NAME}

# export COAP_SERVER_FOLDER_NAME=nanocoap_server
# export COAP_SERVER_EXE_NAME=${COAP_SERVER_FOLDER_NAME}
# export COAP_SERVER_HOME=${SENSE_HOME}/src/network/${COAP_SERVER_FOLDER_NAME}

# export COAP_CLIENT_FOLDER_NAME=gcoap
# export COAP_CLIENT_EXE_NAME=${COAP_CLIENT_FOLDER_NAME}
# export COAP_CLIENT_HOME=${SENSE_HOME}/src/network/${COAP_CLIENT_FOLDER_NAME}

# export COAP_CLIENT_TEST_FOLDER_NAME=gcoap_test
# export COAP_CLIENT_TEST_EXE_NAME=${COAP_CLIENT_TEST_FOLDER_NAME}
# export COAP_CLIENT_TEST_HOME=${SENSE_HOME}/src/network/${COAP_CLIENT_TEST_FOLDER_NAME}

# export SENSOR_READ_FOLDER_NAME=sensor-m3-temperature
# export SENSOR_READ_EXE_NAME=${SENSOR_READ_FOLDER_NAME}
# export SENSOR_READ_HOME=${SENSE_HOME}/src/sensor/${SENSOR_READ_FOLDER_NAME}

# export SENSOR_CONNECTED_FOLDER_NAME=sensor-connected
# export SENSOR_CONNECTED_EXE_NAME=${SENSOR_CONNECTED_FOLDER_NAME}
# export SENSOR_CONNECTED_HOME=${SENSE_HOME}/src/sensor/${SENSOR_CONNECTED_FOLDER_NAME}

# export SENSOR_2_CONNECTED_FOLDER_NAME=sensor2
# export SENSOR_2_CONNECTED_EXE_NAME=${SENSOR_2_CONNECTED_FOLDER_NAME}
# export SENSOR_2_CONNECTED_HOME=${SENSE_HOME}/src/sensor/${SENSOR_2_CONNECTED_FOLDER_NAME}


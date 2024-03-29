#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    if [ -n "$SENSE_FUNCTONS_ENV_UP" ]; then
        echo "Environment already set"
        return 0
    fi
fi

declare -a a8_nodes
declare -a m3_nodes

extract_and_categorize_nodes() {
    local json=$1
    a8_nodes=()
    m3_nodes=()

    # Extract the number of nodes
    local num_nodes=$(echo "$json" | jq '.nb_nodes')

    # Loop through each node and categorize
    for ((i = 0; i < num_nodes; i++)); do
        local node=$(echo "$json" | jq -r ".nodes[$i]")
        if [[ $node == "a8-"* ]]; then
            # Extract the number part for a8 nodes
            local number=$(echo "$node" | cut -d'-' -f2 | cut -d'.' -f1)
            a8_nodes+=("$number")
        elif [[ $node == "m3-"* ]]; then
            # Extract the number part for m3 nodes
            local number=$(echo "$node" | cut -d'-' -f2 | cut -d'.' -f1)
            m3_nodes+=("$number")
        fi
    done
}

flash_elf() {
    local firmware_path=$1
    local node=$2
    local site=${SENSE_SITE} # Default site if SENSE_SITE is not set

    # Execute the command
    echo "iotlab-node --flash "$firmware_path" -l "${site},m3,$node" -i ${EXPERIMENT_ID}"
    iotlab-node --flash "$firmware_path" -l "${site},m3,$node" -i "${EXPERIMENT_ID}"
}

# Function to execute the iotlab-node command with given parameters
flash_firmware() {
    local firmware_name=$1
    local node=$2
    local firmware_path="${SENSE_FIRMWARE_HOME}/${firmware_name}.elf"
    local site=${SENSE_SITE} # Default site if SENSE_SITE is not set

    # Execute the command
    echo "iotlab-node --flash "$firmware_path" -l "${site},m3,$node" -i ${EXPERIMENT_ID}"
    iotlab-node --flash "$firmware_path" -l "${site},m3,$node" -i ${EXPERIMENT_ID}
}

# Function to write a variable to a file
write_variable_to_file() {
    local variable_name=$1
    local variable_value=$2
    local file_path=~/shared/logs/"${variable_name}.txt"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file_path")"

    # Write the variable value to the file
    echo "$variable_value" >"$file_path"
}

# Function to read a variable from a file
read_variable_from_file() {
    local variable_name=$1
    local file_path=~/shared/logs/"${variable_name}.txt"

    # Check if the file exists
    if [ -f "$file_path" ]; then
        cat "$file_path"
    else
        echo "Error: File not found."
        return 1 # Return a non-zero status to indicate failure
    fi
}

extract_global_ipv6() {
    local file_path="$HOME/shared/mqtt_broker_details.txt"

    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        echo "File does not exist: $file_path"
        return 1
    fi

    # Extract the global IPv6 address
    local ipv6_addr=$(grep -o 'inet6 addr: 2001:[^ ]*' "$file_path" | awk '{print $3}')

    if [ -z "$ipv6_addr" ]; then
        echo "Global IPv6 address not found in the file."
        return 1
    fi

    ipv6_addr=${ipv6_addr%???}
    echo "$ipv6_addr"
}

extract_global_ipv6_2() {
    local file_path="$HOME/shared/mqtt_broker_details_2.txt"

    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        echo "File does not exist: $file_path"
        return 1
    fi

    # Extract the global IPv6 address
    local ipv6_addr=$(grep -o 'inet6 addr: 2001:[^ ]*' "$file_path" | awk '{print $3}')

    if [ -z "$ipv6_addr" ]; then
        echo "Global IPv6 address not found in the file."
        return 1
    fi

    ipv6_addr=${ipv6_addr%???}
    echo "$ipv6_addr"
}

extract_local_ipv6() {
    local file_path="$HOME/shared/mqtt_broker_details.txt"

    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        echo "File does not exist: $file_path"
        return 1
    fi

    # Extract the local IPv6 address
    local ipv6_addr=$(grep -o 'inet6 addr: fe80:[^ ]*' "$file_path" | awk '{print $3}')

    if [ -z "$ipv6_addr" ]; then
        echo "Local IPv6 address not found in the file."
        return 1
    fi

    ipv6_addr=${ipv6_addr%???}
    echo "$ipv6_addr"
}

# Function to write the experiment ID to a file
write_experiment_id() {
    local experiment_id=$1
    local file_path=~/shared/logs/experiment_id.txt

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file_path")"

    # Write the experiment ID to the file
    echo "$experiment_id" >"$file_path"
}

# Function to read the experiment ID from a file
read_experiment_id() {
    local file_path=~/shared/logs/experiment_id.txt

    # Check if the file exists
    if [ -f "$file_path" ]; then
        cat "$file_path"
    else
        echo "Error: File not found."
        return 1 # Return a non-zero status to indicate failure
    fi
}

get_running_experiment_id() {
    local experiment_name_to_check="$1"
    local experiment_output=$(iotlab-experiment get -e)

    if [ "$experiment_output" != "{}" ]; then
        local running_experiments=$(echo "$experiment_output" | jq -r '.Running[]')
        for job_id in $running_experiments; do
            local experiment_info=$(iotlab-experiment get -i ${job_id} -p)
            local experiment_name=$(echo "$experiment_info" | jq -r '.name')

            if [ "$experiment_name" == "$experiment_name_to_check" ]; then
                echo $job_id
                return 0 # Experiment found, returning its job ID
            fi
        done
    fi

    echo "No running experiment found with the name $experiment_name_to_check"
    return 1 # No experiment found with the given name
}

is_experiment_running() {
    local experiment_name_to_check="$1"
    local experiment_output=$(iotlab-experiment get -e)

    if [ "$experiment_output" != "{}" ]; then
        local running_experiments=$(echo "$experiment_output" | jq -r '.Running[]')
        for job_id in $running_experiments; do
            local experiment_info=$(iotlab-experiment get -i ${job_id} -p)
            local experiment_name=$(echo "$experiment_info" | jq -r '.name')

            if [ "$experiment_name" == "$experiment_name_to_check" ]; then
                return 0 # True, experiment with the given name is running
            fi
        done
    fi

    return 1 # False, no experiment with the given name is running
}

create_stopper_script() {
    local script_name=$(basename "$0")
    local stopper_name="${script_name}_stopper.sh"
    local stopper_path="${SENSE_STOPPERS_HOME}/${stopper_name}"

    echo "Creating '${stopper_path}' script"
    echo "# Stopper script generated by ${script_name}" >"${stopper_path}"

    for job_id in "$@"; do
        echo "JOB_STATE=\$(iotlab-experiment wait --timeout 30 --cancel-on-timeout -i ${job_id} --state Running,Finishing,Terminated,Stopped,Error)" >>"${stopper_path}"
        echo "if [ \"\$JOB_STATE\" = '\"Running\"' ]; then" >>"${stopper_path}"
        echo "    echo \"Stopping Job ID ${job_id}\"" >>"${stopper_path}"
        echo "    iotlab-experiment stop -i ${job_id}" >>"${stopper_path}"
        echo "else" >>"${stopper_path}"
        echo "    echo \"Job ID ${job_id} is not in 'Running' state. Current state: \$JOB_STATE\"" >>"${stopper_path}"
        echo "fi" >>"${stopper_path}"
        echo "" >>"${stopper_path}" # Adds a newline for readability
    done
}

submit_border_router_job() {
    local border_router_node="$1"

    local border_router_job_json=$(iotlab-experiment submit -n ${BORDER_ROUTER_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},m3,${border_router_node},${SENSE_FIRMWARE_HOME}/${BORDER_ROUTER_EXE_NAME}.elf)

    # Extract job ID from JSON output
    local border_router_job_id=$(echo $border_router_job_json | jq -r '.id')

    echo $border_router_job_id
}

submit_coap_server_job() {
    local coap_server_node="$1"

    local coap_server_job_json=$(iotlab-experiment submit -n ${COAP_SERVER_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE}${SENSE_SITE},m3,${coap_server_node},${SENSE_FIRMWARE_HOME}/${COAP_SERVER_EXE_NAME}.elf)

    # Extract job ID from JSON output
    local coap_server_job_id=$(echo $coap_server_job_json | jq -r '.id')

    echo $coap_server_job_id
}

submit_sensor_node_job() {
    local sensor_connected_node="$1"

    iotlab-profile del -n group12
    iotlab-profile addm3 -n group12 -voltage -current -power -period 8244 -avg 4

    local n_connected_sensor=$(iotlab-experiment submit -n ${SENSOR_CONNECTED_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},m3,${sensor_connected_node},${SENSE_FIRMWARE_HOME}/${SENSOR_CONNECTED_EXE_NAME}.elf,group12)
    local n_connected_sensor_job_id=$(echo $n_connected_sensor | jq '.id')

    echo $n_connected_sensor_job_id
}

submit_compute_node_job() {
    local sensor_connected_node="$1"

    iotlab-profile del -n group12
    iotlab-profile addm3 -n group12 -voltage -current -power -period 8244 -avg 4

    local n_connected_sensor=$(iotlab-experiment submit -n ${COMPUTE_ENGINE_EXE_NAME} -d ${EXPERIMENT_TIME} -l ${SENSE_SITE},m3,${sensor_connected_node},${SENSE_FIRMWARE_HOME}/${COMPUTE_ENGINE_EXE_NAME}.elf,group12)
    local n_connected_sensor_job_id=$(echo $n_connected_sensor | jq '.id')

    echo $n_connected_sensor_job_id
}

wait_for_job() {
    local n_node_job_id="$1"

    echo "DataStreamPilot: iotlab-experiment wait --timeout ${JOB_WAIT_TIMEOUT} --cancel-on-timeout -i ${n_node_job_id} --state Running"
    iotlab-experiment wait --timeout "${JOB_WAIT_TIMEOUT}" --cancel-on-timeout -i "${n_node_job_id}" --state Running
}

create_tap_interface() {
    local node_id="$1"
    local tap_interface="$2"
    local border_router_ip="$3"
    echo "Create tap interface ${tap_interface}"
    echo "nib neigh"
    echo "Creating tap interface..."
    echo "sudo ethos_uhcpd.py m3-${node_id} ${tap_interface} ${border_router_ip}"
    sudo ethos_uhcpd.py m3-${node_id} ${tap_interface} ${border_router_ip}
    sleep 5
    echo "Done creating tap interface..."
}

create_tap_interface_bg() {
    local node_id="$1"
    echo "Create tap interface ${TAP_INTERFACE}"
    echo "nib neigh"
    echo "Creating tap interface..."
    sudo ethos_uhcpd.py m3-${node_id} ${TAP_INTERFACE} ${BORDER_ROUTER_IP} &
    sleep 5
    echo "Done creating tap interface..."
}

stop_jobs() {
    for job_id in "$@"; do
        # Check the state of the job
        JOB_STATE=$(iotlab-experiment wait --timeout 30 --cancel-on-timeout -i ${job_id} --state Running,Terminated,Stopped,Error)

        echo "Job ID ${job_id} State: $JOB_STATE"

        # Stop the job only if it is in 'Running' state
        if [ "$JOB_STATE" = '"Running"' ]; then
            echo "Stopping Job ID ${job_id}"
            iotlab-experiment stop -i ${job_id}
        else
            echo "Job ID ${job_id} is not in 'Running' state. Current state: $JOB_STATE"
        fi

        sleep 1
    done
}

build_wireless_firmware() {

    local firmware_source_folder="$1"
    local exe_name="$2"
    local ARCH="${3:-$ARCH}"
    local channel="${4:-$DEFAULT_CHANNEL}"

    echo "Build firmware ${firmware_source_folder}"
    echo "make ETHOS_BAUDRATE=${ETHOS_BAUDRATE} DEFAULT_CHANNEL=${channel} DEFAULT_PAN_ID="${PANID}"  BOARD=${ARCH} -C ${firmware_source_folder}"
    make ETHOS_BAUDRATE="${ETHOS_BAUDRATE}" UPLINK=ethos DEFAULT_CHANNEL="${channel}" DEFAULT_PAN_ID="${PANID}" BOARD=${ARCH} -C "${firmware_source_folder}"

    # Capture the exit status of the make command
    local status=$?

    # Optionally, you can echo the status for logging or debugging purposes
    if [ $status -eq 0 ]; then
        echo "Build succeeded"
    else
        echo "Build failed with exit code $status"
    fi

    # Return the exit status
    return $status
}

build_wireless_firmware_forced() {

    local firmware_source_folder="$1"
    local exe_name="$2"
    local ARCH="${3:-$ARCH}"
    local channel="${4:-$DEFAULT_CHANNEL}"

    echo "Build firmware ${firmware_source_folder}"
    echo "make ETHOS_BAUDRATE=${ETHOS_BAUDRATE} DEFAULT_CHANNEL=${channel} DEFAULT_PAN_ID="${PANID}" BOARD=${ARCH} -C ${firmware_source_folder}"
    make ETHOS_BAUDRATE="${ETHOS_BAUDRATE}" DEFAULT_CHANNEL="${channel}" DEFAULT_PAN_ID="${PANID}" BOARD="${ARCH}" -C "${firmware_source_folder}"

    # Capture the exit status of the make command
    local status=$?

    # Optionally, you can echo the status for logging or debugging purposes
    if [ $status -eq 0 ]; then
        echo "Build succeeded"
    else
        echo "Build failed with exit code $status"
    fi

    # Return the exit status
    return $status
}

build_wireless_firmware_cached() {

    local firmware_source_folder="$1"
    local exe_name="$2"
    local ARCH="${3:-$ARCH}"
    local channel="${4:-$DEFAULT_CHANNEL}"

    if are_files_new "${firmware_source_folder}/bin/${ARCH}/${exe_name}.elf" "${firmware_source_folder}"; then
        echo "No need to build"
        return 0 # Exit the function successfully
    fi

    echo "Build firmware ${firmware_source_folder}"
    echo "make ETHOS_BAUDRATE=${ETHOS_BAUDRATE} DEFAULT_CHANNEL=${channel} DEFAULT_PAN_ID="${PANID}" BOARD=${ARCH} -C ${firmware_source_folder}"
    make ETHOS_BAUDRATE="${ETHOS_BAUDRATE}" DEFAULT_CHANNEL="${channel}" DEFAULT_PAN_ID="${PANID}" BOARD="${ARCH}" -C "${firmware_source_folder}"

    # Capture the exit status of the make command
    local status=$?

    # Optionally, you can echo the status for logging or debugging purposes
    if [ $status -eq 0 ]; then
        echo "Build succeeded"
    else
        echo "Build failed with exit code $status"
    fi

    # Return the exit status
    return $status
}

build_firmware() {
    local firmware_source_folder="$1"
    local exe_name="$2"
    if are_files_new "${firmware_source_folder}/bin/${ARCH}/${exe_name}.elf" "${firmware_source_folder}"; then
        echo "No need to build"
        return 0 # Exit the function successfully
    fi

    echo "Build firmware ${firmware_source_folder}"
    echo "make BOARD=${ARCH} -C ${firmware_source_folder}"
    make BOARD="${ARCH}" -C "${firmware_source_folder}" clean all

    local status=$?

    # Optionally, you can echo the status for logging or debugging purposes
    if [ $status -eq 0 ]; then
        echo "Build succeeded"
    else
        echo "Build failed with exit code $status"
    fi

    # Return the exit status
    return $status
}

is_first_file_newer() {
    local first_file="$1"
    local second_file="$2"

    if [[ ! -e "$first_file" ]] || [[ ! -e "$second_file" ]]; then
        echo "One or both files do not exist."
        echo "$first_file"
        echo "$second_file"
        return 2 # Return 2 for error due to non-existent files
    fi

    local first_file_mod_time=$(stat -c %Y "$first_file")
    local second_file_mod_time=$(stat -c %Y "$second_file")

    if [[ $first_file_mod_time -gt $second_file_mod_time ]]; then
        return 0 # First file is newer
    elif [[ $first_file_mod_time -le $second_file_mod_time ]]; then
        return 1 # First file is equal or older
    fi
}

are_files_new() {
    local first_file="$1"
    local directory="$2"

    if [[ ! -e "$first_file" ]]; then
        echo "The first file does not exist."
        return 2 # Return 2 for error due to non-existent first file
    fi

    if [[ ! -d "$directory" ]]; then
        echo "The provided directory does not exist."
        return 2 # Return 2 for error due to non-existent directory
    fi

    local first_file_mod_time=$(stat -c %Y "$first_file")
    local newer_found=0

    # Iterate over .c and .h files in the directory
    for file in "$directory"/*.{c,h} "$directory/Makefile" "${SENSE_SCRIPTS_HOME}/setup_env.sh"; do
        if [[ -e $file ]]; then
            local file_mod_time=$(stat -c %Y "$file")
            if [[ $first_file_mod_time -le $file_mod_time ]]; then
                echo "$first_file"
                echo "$file"
                return 1
                break
            fi
        fi
    done

    return 0
}

extract_ip() {
    local server_ip="$1"
    local ip

    # Extracting IP address, assuming it ends 6 characters before the end
    ip="${server_ip:1:${#server_ip}-7}"
    echo "$ip"
}

flash_sensor() {
    local architecture=$1
    local file_to_flash=$2
    local mqtt_client_node=$3
    local emcute_id=$4

    echo "Flashing sensor based on architecture: $architecture"

    if [ "$architecture" = "iotlab-m3" ]; then
        cp $file_to_flash ${SENSE_FIRMWARE_HOME}
        echo "Architecture is iotlab-m3."
        flash_elf $file_to_flash $mqtt_client_node

    elif [ "$architecture" = "iotlab-a8-m3" ]; then
        local remote_file=~/A8/${EMCUTE_MQTSSN_CLIENT_EXE_NAME}_${emcute_id}.elf
        cp $file_to_flash $remote_file
        echo "Architecture is iotlab-a8-m3."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@node-a8-$mqtt_client_node 'bash -s' <${SENSE_HOME}/src/network/emcute_mqttsn_client/mqute_client_${emcute_id}.sh
        echo "ssh root@node-a8-$mqtt_client_node"

    else
        echo "Architecture is something else."
    fi
}

setup_and_check_sensor() {
    local my_arch=$1

    echo "DataStreamPilot: The file to check : $file_to_check."
    echo "DataStreamPilot: My architecture $my_arch."
    file_to_check=${SENSE_HOME}/release/emcute_mqttsn_client_${EMCUTE_ID}.elf

    if [ ! -f "$file_to_check" ]; then
        source ${SENSE_SCRIPTS_HOME}/emcute_mqttsn_client.sh
        echo "ELF NOT FOUND"
    else
        echo "File exists: $file_to_check"
        ELF_FILE=$file_to_check
        echo "Flashing sensor $emcute_id from root script"
        flash_sensor "$my_arch" "$file_to_check" "${MQTT_CLIENT_NODE}" "${EMCUTE_ID}"
    fi
}

write_and_print_variable() {
    local var_name=$1
    local var_value=$2
    local print_prefix=$3

    write_variable_to_file "$var_name" "$var_value"
    printf "%-50s %s\n" "DataStreamPilot: $var_name:" "$print_prefix - $var_value"
}
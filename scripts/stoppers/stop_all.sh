#!/usr/bin/env bash

show_usage() {
    local script_name=$(basename $0)
    echo "----------------------------------------------------------------"
    echo "                    IoT Lab Experiment Stopper                  "
    echo "----------------------------------------------------------------"
    echo "Usage: $script_name [option]"
    echo
    echo "This script stops running IoT Lab experiments."
    echo
    echo "Options:"
    echo "  all           Stop all running experiments."
    echo "  [no option]   Prompt user before stopping each experiment."
    echo
    echo "Examples:"
    echo "  make stop        # Run in interactive mode."
    echo "  make stop all    # Stop all experiments without prompts."
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "help" ]]; then
    show_usage
    exit 0
fi

experiment_output=$(iotlab-experiment get -e)

stop_all_mode=${1:-interactive}

if [ "$experiment_output" != "{}" ]; then
    id_list=$(echo "$experiment_output" | jq '.Running[]')
    # Iterate over each ID and stop the corresponding job
    for job_id in $id_list; do
        echo "Stopping Job ID ${job_id}"

        if [ "$stop_all_mode" != "all" ]; then
            echo "About to stop Job ID ${job_id}."
            experiment_info=$(iotlab-experiment get -i ${job_id} -p)
            experiment_name=$(echo "$experiment_info" | jq -r '.name')

            echo "Do you want to stop this experiment : '${experiment_name}' ? [yes/no/info/all]"
            read user_input

            case $user_input in
            yes) ;;
            info)
                echo "$experiment_info"
                continue
                ;;
            all)
                stop_all_mode=true
                ;;
            *)
                echo "Skipping Job ID ${job_id}"
                continue
                ;;
            esac
        fi
        iotlab-experiment stop -i ${job_id}
        echo "Stopped job with ID: $job_id"
    done
else
    echo "INFO: You dont have experiments to stop"
fi

echo "done experiment stopper"

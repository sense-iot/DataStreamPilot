#!/usr/bin/env bash

echo "------------------------------------"
echo "INFO : You can say : make stop all"
echo "------------------------------------"
echo " "
echo "Starting experiment stopper"
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
                stop_all_without_prompt=true
                ;;
            *)
                echo "Skipping Job ID ${job_id}"
                continue
                ;;
            esac
        fi

        iotlab-experiment get -i ${job_id} -p
        #iotlab-experiment stop -i ${job_id}
        echo "Stopped job with ID: $job_id"
    done
else
    echo "INFO: You dont have experiments to stop"
fi

echo "done experiment stopper"

#!/bin/bash

# Check if PID and total time are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <PID> <total_time> [color]"
    exit 1
fi

pid=$1
total_time=$2
color=${3:-"BLUE"}

# Check if the process exists
if ! ps -p $pid > /dev/null; then
    echo "Process with PID $pid not found."
    exit 1
fi

# Start tracking time
start_time=$(ps -o etimes= -p $pid)
last_percentage=0
while ps -p $pid > /dev/null; do
    current_time=$(ps -o etimes= -p $pid)
    runtime=$((current_time - start_time))
    percentage=$((runtime * 100 / total_time))
    if [ $percentage -ne $last_percentage ]; then
        echo "Percentage of runtime: $percentage % ($runtime s)"
        last_percentage=$percentage
        if [ "$color" == "BLUE" ]; then
            mrbeam_ledstrips_cli progress:$percentage
        else
            mrbeam_ledstrips_cli progress:$percentage:$color
        fi
    fi
    sleep 5
done

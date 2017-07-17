#!/usr/bin/env bash
if [ $(hostname) = "denkbrett" ]; then
    /opt/blink1/commandline/blink1-tool -m 100 --yellow
fi;

sudo vagrant ssh -- -t "sudo /OctoPi/src/variants/mrbeam/build_script.sh mrbeam $1"

if [ $(hostname) = "denkbrett" ]; then
    if [ $? -eq 0 ]; then
        /opt/blink1/commandline/blink1-tool -t 1000 --green --blink 5
        /opt/blink1/commandline/blink1-tool -m 500 --green
    else
        /opt/blink1/commandline/blink1-tool -t 1000 --red --blink 5
        /opt/blink1/commandline/blink1-tool -m 500 --red
    fi;
fi;
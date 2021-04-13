#!/bin/bash -x

# Only call this from the run_vagrant_mrbeam_build.sh script.
# Not tested for standalone usage!

whoami
OCTOPIPATH=/OctoPi

#Update repos used
#sudo -u guy /home/guy/stuff/scripts/gitmirror/update_git_mirrors

for i in `lsof ${OCTOPIPATH}/src/workspace-mrbeam/mount | awk '{print $2}'`; do kill -9 $i; done

rm ${OCTOPIPATH}/src/workspace-mrbeam/*.img
rm ${OCTOPIPATH}/src/workspace-mrbeam/*.zip

pushd ${OCTOPIPATH}
    umount ${OCTOPIPATH}/src/workspace-mrbeam/mount/boot
    umount ${OCTOPIPATH}/src/workspace-mrbeam/mount/dev/pts
    umount ${OCTOPIPATH}/src/workspace-mrbeam/mount
    git pull origin mrbeam
    #export OCTOPI_OCTOPRINT_REPO_BUILD='http://localhost/git/OctoPrint.git/'
    #export OCTOPI_OCTOPIPANEL_REPO_BUILD='http://localhost/git/OctoPiPanel.git/'
    #export OCTOPI_FBCP_REPO_BUILD='http://localhost/git/rpi-fbcp.git/'
    #export OCTOPI_MJPGSTREAMER_REPO_BUILD='http://localhost/git/mjpg-streamer.git/'
    #export OCTOPI_WIRINGPI_REPO_BUILD='http://localhost/git/wiringPi.git/'

    ${OCTOPIPATH}/src/build $1 $2
    pushd src
    ${OCTOPIPATH}/src/variants/mrbeam/release $1 $2
    popd
    chmod 777 ${OCTOPIPATH}/src/*
popd

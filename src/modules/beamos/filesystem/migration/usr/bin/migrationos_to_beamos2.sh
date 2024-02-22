#!/bin/bash

# This script is used to flash the Beam OS 2 to the SD-Card.
# Then the Mr Beam will start to Beam OS 2.

# This script uses migration.sh script

# Usage:
#   Flash the SD-Card
#   Mount the SD-Card
#   Restore Sensitive Data
#   Set LED Status Success/Fail
#   Reboot the device

timestamp()
{
 date +"%Y-%m-%d %T"
}

## functions for logging output
log() {
  echo "$(date +"%Y.%m.%d %H:%M:%S") $SCRIPTNAME> $1" 2>&1 | tee -a $LOG_FILE | tee -a $2 >> /dev/null
}

cmd() {
  # tee does not complain if $2 is not set
  echo "$(date +"%Y.%m.%d %H:%M:%S") $SCRIPTNAME> $1" 2>&1 | tee -a $LOG_FILE | tee -a $2 >> /dev/null
  eval "$1" 2>&1 | tee -a $LOG_FILE | tee -a $2 >> /dev/null
  return ${PIPESTATUS[0]}
}

do_exit()
{
  RET_CODE="$?"
  log "$(timestamp) $0: Exitting. ${RET_CODE}"
  if [ "$RET_CODE" -eq 0 ]; then
    log "$0: Normal exiting."
    sudo bash ${BASEDIR}/migration.sh set-status success
  else
    log "$0: Exiting with error code [${RET_CODE}]"
    sudo bash ${BASEDIR}/migration.sh set-status fail orange
  fi
}


###############################################
# Constants
###############################################
BASEDIR="/usr/bin"
SCRIPTNAME=$(basename "$BASH_SOURCE")

LOG_LOCATION="/mnt/usb"
LOG_FILE="${LOG_LOCATION}/migrationos_to_beamos2.log"

SYSLOG_LOCATION="/var/log/syslog"
SYSLOG_BACKUP="${LOG_LOCATION}/migrationos_syslog.log"

SDCARD_ROOTFS_A_PATH="/mnt/sd-card/rootfs_a"
SDCARD_ROOTFS_B_PATH="/mnt/sd-card/rootfs_b"

IMAGE_DIR="/home/pi/image"
BEAMOS2_IMAGE="${IMAGE_DIR}/beamos2.wic.bz2"
MAX_TIME=900 # 15 minutes in seconds
PHASE_COLOR="ORANGE"


###############################################
# Main function
###############################################

# Set trap before EXIT
trap do_exit EXIT

# find the right device name of partition 3 on the USB stick and mount it
echo "$(timestamp) $0: Mounting the USB stick partition 3"
USB_PART=$(lsblk -o NAME,SIZE -d -p -n | grep "/dev/sd" | awk '{print $1}')
USB_PARTITION="${USB_PART}3"
sudo mkdir -p ${LOG_LOCATION}
sudo fsck -a ${USB_PARTITION}
sudo mount ${USB_PARTITION} ${LOG_LOCATION}
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  echo "$(timestamp) $0: mount ${USB_PARTITION} on ${LOG_LOCATION} failed"
fi
echo "$(timestamp) $0: Mounting the USB stick partition 3 successful"

# start progress leds
current_pid=$$
sudo bash ${BASEDIR}/progress.sh $current_pid $MAX_TIME $PHASE_COLOR &>> $LOG_FILE &

#   Flash the SD-Card
log "$(timestamp) $0: Flashing the SD-Card"
cmd 'sudo bash ${BASEDIR}/migration.sh flash beamos2 sd-card'
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  log "$(timestamp) $0: Flashing the SD-Card failed"
  exit 100
fi

#   Mount the SD-Card
log "$(timestamp) $0: Mounting the SD-Card"
cmd 'sudo bash ${BASEDIR}/migration.sh mount sd-card'
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  log "$(timestamp) $0: Mounting the SD-Card failed"
  exit 100
fi

#   Restore Sensitive Data
log "$(timestamp) $0: Restoring Sensitive Data"
cmd 'sudo bash ${BASEDIR}/migration.sh restore-data'
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  log "$(timestamp) $0: Restoring Sensitive Data failed"
  exit 100
fi

# Copy syslog to the USB stick
log "$(timestamp) $0: Copying syslog to the USB stick"
# Check if the file exists and rename it if it does
if [ -f ${SYSLOG_BACKUP} ]; then
  cmd 'sudo mv ${SYSLOG_BACKUP} ${SYSLOG_BACKUP}.old'
fi
cmd 'sudo cp ${SYSLOG_LOCATION} ${SYSLOG_BACKUP}'
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  log "$(timestamp) $0: Copy syslog to the USB stick failed"
fi
log "$(timestamp) $0: Copying syslog to the USB stick successful"

# Copy logs on the /mnt/usb to the freshly flashed SD-Card rootfs var log partition
log "$(timestamp) $0: Copying logs to the freshly flashed SD-Card rootfs var log partition"
log "$(timestamp) $0: System will reboot after this........"
sudo cp -r ${LOG_LOCATION}/* ${SDCARD_ROOTFS_A_PATH}/var/log/
sudo cp -r ${LOG_LOCATION}/* ${SDCARD_ROOTFS_B_PATH}/var/log/
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  echo "$(timestamp) $0: Copying logs to the freshly flashed SD-Card rootfs var log partition failed"
fi

# Reboot the device
echo "$(timestamp) $0: Reboot the device"
sudo bash ${BASEDIR}/migration.sh set-status success
sudo bash ${BASEDIR}/migration.sh reboot
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  echo "$(timestamp) $0: Reboot the device failed"
  exit 100
fi

exit 0

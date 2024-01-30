#!/bin/bash
# bash required for array syntax support.
# This is a copy of the migration.sh script from the mrb3-usb-stick-builder repo.

echo "Beam OS1 to Beam OS2 Migration Script"

usage () {
    echo "Beam OS1 to Beam OS2 Migration Script     v1.0.0                                                  "
    echo "                                                                                                  "
    echo "OPTIONS:                                                                                          "
    echo "                                                                                                  "
    echo "  --help                  Print this help message and exit.                                       "
    echo "                                                                                                  "
    echo "COMMANDS:                                                                                         "
    echo "  precondition-checks     Checks the sw and hw components so that Mr Beam can be upgrade or not.  "
    echo "  flash <os> <device>     Flashes the <device> with using <os>.                                   "
    echo "                            - <os> can be \"beamos2\" or \"migrationos\".                         "
    echo "                            - <device> can be \"sd-card\" or device path like \"/dev/sda\".       "
    echo "  mount <device>          Mounts the partitions of <device>.                                      "
    echo "                            - <device> can be \"sd-card\" or device path like \"/dev/sda\".       "
    echo "  preserve-data           Preserves sensitive data into USB at path \"/mnt/usb\".                 "
    echo "  restore-data            Restores sensitive data into SD-Card.                                   "
    echo "  set-status <status>     Sets the <status> of LED. <status> can be one of the following:         "
    echo "                            - success                                                             "
    echo "                            - fail                                                                "
    echo "                            - in-progress                                                         "
    echo "  config-boot-usb         Configures Mr Beam to be able to boot from USB.                         "
    echo "  shutdown                Shutdown Mr Beam.                                                       "

}

timestamp()
{
 date +"%Y-%m-%d %T"
}

do_precondition_checks () {
  echo "$(timestamp) $0: precondition-checks"

  configfile="/home/pi/.octoprint/config.yaml"

  local MIN_REQ_MRBEAM_PLUGIN_VERSION="0.15.1"
  #Check the MrBeamPlugin version
  mrbeam_plugin_version=$(/home/pi/oprint/bin/pip list | grep Mr-Beam | awk '{gsub(/[()]/,""); print $2}')

  if $(dpkg --compare-versions "$mrbeam_plugin_version" "lt" $MIN_REQ_MRBEAM_PLUGIN_VERSION); then
    echo "$(timestamp) $0: MrBeamPlugin version - $mrbeam_plugin_version must be greater than $MIN_REQ_MRBEAM_PLUGIN_VERSION for Migration."
    exit 1
  fi
  echo "$(timestamp) $0: MrBeamPlugin version is $mrbeam_plugin_version. Migration can be done."

  # Create a file to store the list of files to skip backing up
  sudo touch ${SKIP_FILE_NAME} || true
  echo "" > ${SKIP_FILE_NAME}
  # Check if salt is present in config.yaml and decide if users.yaml, users-dev.yaml should be preserved or not
  is_salt_in_config=$(( $(sed -n 's/^[[:space:]]*salt:[[:space:]]*\(.*\)/\1/p' "$configfile" | wc -c) > 0 ))
  if [ $is_salt_in_config -eq 0 ]; then
    echo "$(timestamp) $0: Salt is not present in config.yaml. Files will be skipped in preserve-data."
    sed -i -e '$a\' -e '/home\/pi\/.octoprint\/users.yaml' -e '$a\' -e '/home\/pi\/.octoprint\/users-dev.yaml' ${SKIP_FILE_NAME}
  fi

  # Verify integrity of /etc/mrbeam file. Fail if any field is empty or file doesnt exist.
  # Check if the file exists
  if [ ! -f "/etc/mrbeam" ]; then
    echo "$(timestamp) $0: /etc/mrbeam file not found."
    exit 1
  fi
   # Read each line from the file
  while IFS= read -r line; do
      # Check if the line is not empty
      if [ -n "$line" ]; then
          # Split the line into key and value
          key=$(echo "$line" | cut -d'=' -f1)
          value=$(echo "$line" | cut -d'=' -f2-)

          # Check if the value is empty
          if [ -z "$value" ]; then
              echo "$(timestamp) $0: File /etc/mrbeam is corrupt. Empty value for key: $key"
              exit 1
          fi
      fi
  done < "/etc/mrbeam"
  echo "$(timestamp) $0: /etc/mrbeam is valid. No empty fields found."

  # Get the list of USB block devices with sizes in bytes
  USB_DRIVES=$(lsblk -o NAME,SIZE,TYPE,TRAN -dn --bytes | grep 'usb' | awk '{print $1,$2}')

  # Check if there are any USB drives
  if [ -z "$USB_DRIVES" ]; then
    echo "$(timestamp) $0: No USB drives found."
    exit 1
  fi

  while read -r line; do
    DEVICE_SIZE_BYTES=$(echo "$line" | awk '{print $2}')

    # Check if the size is greater than 4GB
    if [ "$DEVICE_SIZE_BYTES" -gt $((MIN_USB_SIZE_IN_GB * 1024 * 1024 * 1024)) ]; then
      DEVICE_SIZE_GIGABYTES=$((DEVICE_SIZE_BYTES / 1024 / 1024 / 1024))
      echo "$(timestamp) $0: USB drive of $DEVICE_SIZE_GIGABYTES GB present."
      exit 0
    fi

  done <<< "$USB_DRIVES"

  echo "$(timestamp) $0: No USB drive of size greater than ${MIN_USB_SIZE_IN_GB}GB found."
  exit 1
}


find_current_booted_os_version () {
  if [ -f /etc/beamos_version ] || [ -f /etc/octopi_version ] ; then
    echo "beamos1"
  elif [ -f /etc/migrationos_version ]; then
    echo "migrationos"
  fi
}

do_flash () {
  OS_TO_BE_FLASHED="$1"
  DEVICE_TO_BE_FLASHED="$2"
  echo "$(timestamp) $0: flash $OS_TO_BE_FLASHED $DEVICE_TO_BE_FLASHED"

  CURRENT_OS_VERSION=$(find_current_booted_os_version)
  echo "$(timestamp) $0: Flashing $OS_TO_BE_FLASHED on $DEVICE_TO_BE_FLASHED from $CURRENT_OS_VERSION"
  if [ "$OS_TO_BE_FLASHED" = "beamos2" ] && [ "$DEVICE_TO_BE_FLASHED" = "sd-card" ] && [ "$CURRENT_OS_VERSION" = "migrationos" ]; then
    echo "Flashing SD-Card with beamos2"
    IMAGE_FILE="${BEAMOS2_IMAGE}"
    # check if the image is there
    if [ ! -f ${IMAGE_FILE} ]; then
      echo "$(timestamp) $0: Image not found: ${IMAGE_FILE}"
      exit 1
    fi
    sudo umount ${SD_CARD_DEVICE}* || true
    sudo bmaptool copy ${IMAGE_FILE} ${SD_CARD_DEVICE}
    STATUS=$?
  elif [ "$OS_TO_BE_FLASHED" = "migrationos" ] && [ "$CURRENT_OS_VERSION" = "beamos1" ];then
    # check if the image is there
    IMAGE_FILE="${MIGRATION_IMAGE}"
    if [ ! -f ${IMAGE_FILE} ]; then
      echo "$(timestamp) $0: Image not found: ${IMAGE_FILE}"
      exit 1
    fi
    echo "$(timestamp) $0: Flashing USB with migrationos"
    sudo umount ${DEVICE_TO_BE_FLASHED}* || true
    sudo dd if=${IMAGE_FILE} of=${DEVICE_TO_BE_FLASHED} bs=4M conv=fsync
    STATUS=$?
  else
    echo "$(timestamp) $0: Check inputs to the function flash"
    exit 1
  fi

  # check status of flashing
  if [ $STATUS -ne 0 ]; then
    echo "$(timestamp) $0: Flashing Failed - $OS_TO_BE_FLASHED on $DEVICE_TO_BE_FLASHED from $CURRENT_OS_VERSION"
    exit 1
  fi

  sudo sync

  echo "$(timestamp) $0: Flashing Successful - $OS_TO_BE_FLASHED flashed into $DEVICE_TO_BE_FLASHED "
  exit 0
}

do_mount () {
  DEVICE_TO_BE_MOUNTED="$1"
  echo "$(timestamp) $0: mount $DEVICE_TO_BE_MOUNTED" # "sd-card" or usb path like "/dev/sda"
  CURRENT_OS_VERSION=$(find_current_booted_os_version)

  if [ "$DEVICE_TO_BE_MOUNTED" = "sd-card" ] && [ "$CURRENT_OS_VERSION" = "migrationos" ]; then
    # Mounting the SD-Card
    DEVICE_PARTITIONS=(
      ${SDCARD_ROOTFS_A}
      ${SDCARD_ROOTFS_B}
      ${SDCARD_HOME}
    )

    MOUNT_DIRS=(
      ${SDCARD_ROOTFS_A_PATH}
      ${SDCARD_ROOTFS_B_PATH}
      ${SDCARD_HOME_PATH}
    )
  elif [ "$DEVICE_TO_BE_MOUNTED" != "sd-card" ] && [ "$CURRENT_OS_VERSION" = "beamos1" ];then
    # Mounting the USB with migrationos
    # There are 2 partitions on the USB. The first one is the boot partition and the second one is the rootfs.
    DEVICE_PARTITION=${DEVICE_TO_BE_MOUNTED}2

    DEVICE_PARTITIONS=(
      ${DEVICE_PARTITION}
    )

    MOUNT_DIRS=(
      ${USB_MOUNT_PATH}
    )
  else
    echo "$(timestamp) $0: Check inputs to the function mount"
    exit 1
  fi

  for i in "${!DEVICE_PARTITIONS[@]}"; do
    sudo mkdir -p ${MOUNT_DIRS[$i]}
    echo "$(timestamp) $0: Mounting ${DEVICE_PARTITIONS[$i]} on ${MOUNT_DIRS[$i]}"
    sudo mount ${DEVICE_PARTITIONS[$i]} ${MOUNT_DIRS[$i]}
    # Check if the mount is successful
    if [ $? -ne 0 ]; then
      echo "$(timestamp) $0: Can't mount ${DEVICE_PARTITIONS[$i]}"
      exit 1
    fi
  done

  echo "Mounting Successful - $DEVICE_TO_BE_MOUNTED"


  exit 0
}


do_preserve_data () {
  echo "$(timestamp) $0: preserve-data $USB_MOUNT_PATH" # path like "/mnt/usb"
  if [ -z "${USB_MOUNT_PATH}" ]; then
      echo "$(timestamp) $0: No suitable backup partition found. Exiting..."
      exit 1
  fi

  # Create a backup directory (if it doesn't exist)
  BACKUP_BASE="${USB_MOUNT_PATH}${BACKUP_PATH}"

  # Check if the folder exists, backup if yes.
  if [ -d "${BACKUP_BASE}" ]; then
      # Get the creation time of the folder
      creation_time=$(stat -c %W "${BACKUP_BASE}")

      # Format the creation time as a timestamp
      timestamp=$(date -d "@$creation_time" +"%Y%m%d_%H%M%S")

      # Rename the folder by adding the timestamp
      new_folder_name="${BACKUP_BASE}_backup_${timestamp}"
      mv "${BACKUP_BASE}" "${new_folder_name}"

      echo "$(timestamp) $0: ${BACKUP_BASE} exists. Moved it to: ${new_folder_name}"
  fi

  mkdir -p "$BACKUP_BASE"

  mapfile -t LIST_TO_SKIP < ${SKIP_FILE_NAME}

  SKIPPED=0

  # Loop through each file in the array and create a backup copy
  for FILE in "${DATA_TO_PRESERVE[@]}"; do
    if [ -f "${FILE}" ] || [ -d "${FILE}" ]; then
        if [[ " ${LIST_TO_SKIP[@]} " =~ " $FILE " ]]; then
          echo "$(timestamp) $0: Warning - File ${FILE} skipped as salt is not present in config.yaml"
          ((SKIPPED++))
          continue
        fi
      TARGET_DIR="${BACKUP_BASE}/$(dirname "${FILE}")"
      mkdir -p ${TARGET_DIR}
      TARGET="${TARGET_DIR}/$(basename "${FILE}")"
      cp -r "${FILE}" "${TARGET}"
      echo "$(timestamp) $0: Success - copied '${FILE}' to '${TARGET}'"
    else
      echo "$(timestamp) $0: Warning - File '${FILE}' not found. Skipping."
      ((SKIPPED++))
    fi
  done

  echo "$(timestamp) $0: Backup process completed. Backup copies are stored in '$BACKUP_BASE'."
  if [ "${SKIPPED}" -gt 0 ]; then
    echo "$(timestamp) $0: Warning - ${SKIPPED} files were skipped - Please check syslog."
    # exit 1
  fi

  exit 0
}

do_restore_data () {
  echo "$(timestamp) $0: restore-data"

  # /etc/hostname -> Rootfs A and B -> /etc/hostname
  echo "$(timestamp) $0: Restoring /etc/hostname to Rootfs A and B /etc/hostname"
  sudo cp ${BACKUP_PATH}/etc/hostname ${SDCARD_ROOTFS_A_PATH}/etc/hostname
  sudo cp ${BACKUP_PATH}/etc/hostname ${SDCARD_ROOTFS_B_PATH}/etc/hostname

  # /etc/hosts -> Home -> /home/root/mrbeam-base-files/hosts
  echo "$(timestamp) $0: Restoring /etc/hosts to Home /home/root/mrbeam-base-files/hosts"
  sudo cp ${BACKUP_PATH}/etc/hosts ${SDCARD_HOME_PATH}/root/mrbeam-base-files/hosts

  # /etc/mrbeam -> Home -> /home/pi/mrbeam-id/mrbeam
  # We need to understand backed up from beamos0 or beamos1
  echo "$(timestamp) $0: Restoring /etc/mrbeam to Home /home/pi/mrbeam-id/mrbeam"
  local MRBEAM_SECTION="Mr Beam"
  sudo crudini --get "${BACKUP_PATH}/etc/mrbeam" "$MRBEAM_SECTION" "production_date"
  if [ $? -ne 0 ]; then
    # We are migrating from beamos0
    echo "$(timestamp) $0: Migrating from beamos0"
    SECTION=""
  else
    # We are migrating from beamos1
    echo "$(timestamp) $0: Migrating from beamos1"
    SECTION="Mr Beam"
  fi
  # Below params will be set to the new mrbeam file
  PARAMS="production_date hostname device_series device_type serial model"
  for param in $PARAMS; do
    local VALUE=$(sudo crudini --get "${BACKUP_PATH}/etc/mrbeam" "$SECTION" "$param")
    echo "$(timestamp) $0: Setting $param to $VALUE"
    sudo crudini --set "${SDCARD_HOME_PATH}/pi/mrbeam-id/mrbeam" "$MRBEAM_SECTION" "$param" "${VALUE}"
  done
  local OCTOPI=$(sudo crudini --get "${BACKUP_PATH}/etc/mrbeam" "$SECTION" "octopi")
  # Set migrated_from param
  echo "$(timestamp) $0: Setting migrated_from to $OCTOPI"
  sudo crudini --set "${SDCARD_HOME_PATH}/pi/mrbeam-id/mrbeam" "$MRBEAM_SECTION" "migrated_from" "${OCTOPI}"
  # Set need_reboot param
  sudo crudini --set "${SDCARD_HOME_PATH}/pi/mrbeam-id/mrbeam" "$MRBEAM_SECTION" "need_reboot" true

  # .octoprint/config.yaml -> Home -> /home/pi/.octoprint/config.yaml
  # We need to copy fields from the backup to the new config.yaml
  backupfolder="${BACKUP_PATH}"
  applyfolder="${SDCARD_HOME_PATH}/.."
  configfile="/home/pi/.octoprint/config.yaml"
  backupfile="${backupfolder}${configfile}"
  applyfile="${applyfolder}${configfile}"
  migrationoperator="workshop"
  #accessControl needed for users.yaml
  echo "$(timestamp) $0: Restoring accessControl for $configfile"
  sudo cat $backupfile | sudo yq ea -i 'select(fileIndex==0) * {"accessControl":select(fileIndex==1).accessControl}' $applyfile -

  #plugins.findmymrbeam
  echo "$(timestamp) $0: Restoring plugins.findmymrbeam for $configfile"
  sudo cat $backupfile | sudo yq ea -i 'select(fileIndex==0) * {"plugins":{"findmymrbeam":select(fileIndex==1).plugins.findmymrbeam}}' $applyfile -

  #plugins.mrbeam.analyticsEnabled
  echo "$(timestamp) $0: Restoring plugins.mrbeam.analyticsEnabled for $configfile"
  sudo cat $backupfile | sudo yq ea -i 'select(fileIndex==0) * {"plugins":{"mrbeam":{"analyticsEnabled":select(fileIndex==1).plugins.mrbeam.analyticsEnabled}}}' $applyfile -

  #plugins.mrbeam.review
  echo "$(timestamp) $0: Restoring plugins.mrbeam.review for $configfile"
  sudo cat $backupfile | sudo yq ea -i 'select(fileIndex==0) * {"plugins":{"mrbeam":{"review":select(fileIndex==1).plugins.mrbeam.review}}}' $applyfile -

  #plugins.swupdater.attributes.migration-operator
  echo "$(timestamp) $0: Save plugins.swupdater.server_url and plugins.swupdater.server_port from $applyfile"
  server_url=$(sudo yq eval '.plugins.swupdater.server_url' $applyfile)
  server_port=$(sudo yq eval '.plugins.swupdater.server_port' $applyfile)
  echo "$(timestamp) $0: Set plugins.swupdater.attributes.migration-operator as $migrationoperator for $configfile"
  sudo yq e -i ".plugins.swupdater |= {\"server_url\": \"$server_url\", \"server_port\": $server_port, \"attributes\": {\"migration-operator\": \"$migrationoperator\"}}" $applyfile

  #We now set a field to identify this as a first boot after upgrade
  #plugins.mrbeam.firstBootAfterUpgrade
  echo "$(timestamp) $0: Set plugins.mrbeam.firstBootAfterUpgrade for $configfile"
  sudo yq eval -i '.plugins.mrbeam.firstBootAfterUpgrade = true' $applyfile

  # Run python script to sanitize lens calibration files
  echo "$(timestamp) $0: Sanitizing lens calibration files"
  sanitize_npz.py

  # Loop through the rest of the files and folders in the array and copy backed up files
  echo "$(timestamp) $0: Restoring the rest of the files to Home"
  for FILE in "${DATA_TO_RESTORE[@]}"; do
    BACKUP_FILE="${BACKUP_PATH}/home/pi/${FILE}"
    if [ -f "${BACKUP_FILE}" ] || [ -d "${BACKUP_FILE}" ]; then
      TARGET_DIR="${SDCARD_HOME_PATH}/pi/$(dirname "${FILE}")"
      sudo mkdir -p ${TARGET_DIR}
      TARGET="${TARGET_DIR}/$(basename "${FILE}")"
      echo "$(timestamp) $0: Restoring ${BACKUP_FILE} to ${TARGET}"
      sudo cp -r "${BACKUP_FILE}" "${TARGET}"
    else
      echo "$(timestamp) $0: Restore data: Warning - File '${FILE}' not found. Skipping."
    fi
  done

  # Give admin permission to all users in the users.yaml file
  # This is default in our implementation of OctoPrint access control
  usersyamlfilelist=(
  "${SDCARD_HOME_PATH}/pi/.octoprint/users.yaml"
  "${SDCARD_HOME_PATH}/pi/.octoprint/users-dev.yaml"
  )

  for usersyamlfile in "${usersyamlfilelist[@]}"; do
    if [ ! -f "$usersyamlfile" ]; then
      echo "$(timestamp) $0: Restore data: Warning - File '${usersyamlfile}' not found. Skipping."
      continue
    fi
    # Extract email addresses with a trailing colon
    email_list=$(grep -E -o '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b:' "$usersyamlfile" | sed 's/:$//')

    for email in $email_list; do
        # Check if 'admin' role already exists for the email
        admin_exists=$(sudo yq eval ".\"$email\".roles | select(.[] == \"admin\")" "$usersyamlfile")

        # If 'admin' role does not exist, append it
        if [ -z "$admin_exists" ]; then
            sudo yq eval -i ".\"$email\".roles += [\"admin\"]" "$usersyamlfile"
        fi

        # Check if 'groups' field exists for the email
        groups_exists=$(yq eval ".\"$email\".groups" "$usersyamlfile")

        # If 'groups' field does not exist, add it with specified values
        if [ "$groups_exists" == "null" ]; then
            sudo yq eval -i ".\"$email\".groups = [\"admins\", \"users\"]" "$usersyamlfile"
        fi
    done
  done

  echo "$(timestamp) $0: Restore data: Restore process completed."
  exit 0
}

set_status_success() {
  echo "$(timestamp) $0: status_success"
  mrbeam_ledstrips_cli flash_green
  sleep 1
  mrbeam_ledstrips_cli green
}

set_status_fail () {
  echo "$(timestamp) $0: status_fail"
  mrbeam_ledstrips_cli flash_red
  sleep 1
  mrbeam_ledstrips_cli red
}

set_status_in_progress () {
  echo "$(timestamp) $0: status_in_progress"
  mrbeam_ledstrips_cli flash_color:120:120:120:4;
  sleep 0.4 ;
  mrbeam_ledstrips_cli flash_color:40:40:40:5
}

do_set_status () {
  STATUS="$1"
  echo "$(timestamp) $0: set-status ${STATUS}"
  if [ "${STATUS}" = "success" ]; then
    echo "${STATUS}"
    set_status_success
  elif [ "${STATUS}" = "fail" ]; then
    echo "${STATUS}"
    set_status_fail
  elif [ "${STATUS}" = "in-progress" ]; then
    echo "${STATUS}"
    set_status_in_progress
  else
    echo "$(timestamp) $0: Unknown status [${STATUS}]"
    set_status_fail
  fi
  exit 0
}

do_config_boot_usb () {
  echo "$(timestamp) $0: config-boot-usb"
  echo program_usb_boot_mode=1 | sudo tee -a /boot/config.txt
  sudo sed -i '$ s|$| root=/dev/sda2|' /boot/cmdline.txt
  echo "$(timestamp) $0: Device configured to boot from USB."
  exit 0
}

do_shutdown () {
  echo "$(timestamp) $0: shutdown"
  sudo shutdown now
  exit 0
}


do_exit () {
    RET_CODE="$?"
    echo "$0: Exitting. ${RET_CODE}"
    if [ "$RET_CODE" -eq 0 ]; then
        echo "$0: Normal exiting."
    else
        echo "$0: Exiting with error code [${RET_CODE}]"
        set_status_fail
    fi
}

################################################################################
## migration.sh script configuration
################################################################################

IMAGE_DIR="/home/pi/image"
MIGRATION_IMAGE="${IMAGE_DIR}/migrationos.img"
BEAMOS2_IMAGE="${IMAGE_DIR}/beamos2.wic.bz2"
MIN_USB_SIZE_IN_GB=4
BACKUP_PATH="/mrbeam/preserve-data"
SKIP_FILE_NAME="./files_to_skip_preserve_data"

# There are 8 partitions on the SD-Card.
# Root filesystems are on partition 2 and 3.
# Home is on partition 8.
SD_CARD_DEVICE="/dev/mmcblk0"
SDCARD_ROOTFS_A="${SD_CARD_DEVICE}p2"
SDCARD_ROOTFS_B="${SD_CARD_DEVICE}p3"
SDCARD_HOME="${SD_CARD_DEVICE}p8"

SDCARD_ROOTFS_A_PATH="/mnt/sd-card/rootfs_a"
SDCARD_ROOTFS_B_PATH="/mnt/sd-card/rootfs_b"
SDCARD_HOME_PATH="/mnt/sd-card/home"

USB_MOUNT_PATH="/mnt/usb"

# list of files treated by preserve-data and restore-data
DATA_TO_PRESERVE=(
  "/home/pi/.octoprint/cam" # is a folder
  "/home/pi/.octoprint/analytics/usage.yaml"
  "/home/pi/.octoprint/users.yaml"
  "/home/pi/.octoprint/users-dev.yaml"
  "/home/pi/.octoprint/materials.yaml"
  "/home/pi/.octoprint/laser_heads.yaml"
  "/home/pi/.octoprint/config.yaml"
  "/etc/mrbeam"
  "/etc/network/interfaces"
  "/etc/hostname"
  "/etc/hosts"
  "/etc/network/interfaces.d/wlan0-netconnectd_wifi"
  "/var/log/mount_manager.log"
  # Add more file paths as needed
)

DATA_TO_RESTORE=(
  ".octoprint/cam" # is a folder
  ".octoprint/analytics/usage.yaml"
  ".octoprint/users.yaml"
  ".octoprint/users-dev.yaml"
  ".octoprint/materials.yaml"
  # Other files are required manual intervention to restore
)


################################################################################
## Main
################################################################################


# Present usage.
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

while getopts ":h?:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    esac
done

# Set trap before EXIT
trap do_exit EXIT

# Process all commands.
while true ; do
    case "$1" in
        precondition-checks)
            do_precondition_checks
            shift
            break
            ;;
        flash)
            do_flash "$2" "$3"
            shift
            shift
            shift
            break
            ;;
        mount)
            do_mount "$2"
            shift
            shift
            break
            ;;
        preserve-data)
            do_preserve_data
            shift
            break
            ;;
        restore-data)
            do_restore_data
            shift
            break
            ;;
        set-status)
            do_set_status "$2"
            shift
            shift
            break
            ;;
        config-boot-usb)
            do_config_boot_usb
            shift
            break
            ;;
        shutdown)
            do_shutdown
            shift
            break
            ;;
        *)
            if [[ -n "$1" ]]; then
                echo "$0: Unknown command [${1}]"
                usage
            fi
            break
            ;;
    esac
done

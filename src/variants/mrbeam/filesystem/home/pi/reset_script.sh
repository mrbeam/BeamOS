#!/bin/bash
# run with sudo because some commands work on system files which need root priviliges.

pushd /home/pi/.octoprint
  # Cleanup entries in the config.yaml
  sed -i '/firstRun:/d' config.yaml
  sed -i '/secretKey:/d' config.yaml
  sed -i '/upnpUuid:/d' config.yaml
  sed -i '/seenWizards:/,+1d' config.yaml
  sed -i '/api:/,+1d' config.yaml
  sed -i '/accessControl:/,+1d' config.yaml

  # Delete users.yaml
  rm users.yaml

  pushd uploads
    # Cleanup the uploads dir (delete all files but the listed)
    find . -maxdepth 1 -type f \
      -not -name 'Focus_Lehre.svg' \
      -not -name 'MrBeam.svg' \
      -not -name 'MrBeam_Logo.svg' \
      -not -name 'Schlusselanhanger.svg' \
      | xargs rm --
    pushd cam
      rm *.jpg
    popd
  popd
popd

pushd /etc/network/
  # Delete configured Wifi
  sed -i '/wlan0-netconnectd_wifi/,+3d' interfaces
popd

# Cleanup history
rm /home/pi/.bash_history
history -c

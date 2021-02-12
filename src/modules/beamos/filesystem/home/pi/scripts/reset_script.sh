#!/bin/bash

# in case of an error, flash red
trap signal_err ERR

signal_err() {
  mrbeam_ledstrips_cli flash_red
  sleep 1
  mrbeam_ledstrips_cli red
  exit 1
}

siganl_ok() {
  mrbeam_ledstrips_cli flash_green
  sleep 1
  mrbeam_ledstrips_cli green
}

sudo systemctl stop octoprint.service

pushd /home/pi/.octoprint
  # Cleanup entries in the config.yaml
  sed -i '/firstRun:/d' config.yaml
  sed -i '/secretKey:/d' config.yaml
  sed -i '/upnpUuid:/d' config.yaml
  sed -i '/seenWizards:/,+1d' config.yaml
  sed -i '/api:/,+1d' config.yaml
  sed -i '/accessControl:/,+1d' config.yaml

  # Delete users.yaml
  rm -f users.yaml

  pushd uploads
    # Cleanup the uploads dir (delete all files but the listed)
    find . -maxdepth 1 -type f \
      -not -name 'Focus_Lehre*.svg' \
      -not -name 'MrBeam.svg' \
      -not -name 'MrBeam_Logo.svg' \
      -not -name 'Schlusselanhanger.svg' \
      -delete

    rm cam/*
    rm local/*
  popd
popd

pushd /etc/network/
  # Delete configured Wifi
  sudo sed -i '/wlan0-netconnectd_wifi/,+3d' interfaces
popd

# flash green
siganl_ok



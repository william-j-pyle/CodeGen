#!/bin/bash

function usage() {
  if [ $# -ne 0 ]; then
    echo "$@"
    echo "---------------------------------------------------------------"
  fi
  echo "Usage: $(basename $0) [flags] {device-config file(s)}"
  echo '  -a     Performs Dashboard, ESP, and TFT Builds and Deploys'
  echo '  -d     Dashboard Build and Deploy'
  echo '         Equivilant to flags [ -dB -dD]'
  echo '  -dB    Dashboard Build'
  echo '         Home Assistant Dashboard YAML is built into build directory'
  echo '  -dD    Dashboard Deploy'
  echo '         Deploy Dashboard YAML to Home Assistant'
  echo '         Performs service call to refresh'
  echo '  -eB    ESP Build'
  echo '         YAML file is generated into build directory'
  echo '  -eC    ESP Compile'
  echo '         YAML file is copied from build to HASS Server'
  echo '         ESPHome is triggered to compile YAML file'
  echo '  -eO    ESP OTA (Over The Air) update'
  echo '         IP Address is determined for device'
  echo '         OTA update is performed by ESPHome to device'
  echo '  -e     Performs ESP Build, Compile, and OTA'
  echo '         Equivilant to flags [-eB -eC -eO]'
  echo '  -tB    HMI Build'
  echo '         Fonts are processed into Nextion format, placed in build'
  echo '         Images are processed into Nextion format, placed in build'
  echo '         HMI(TFT Source file) is generated into build'
  echo '         ** Resulting HMI can be edited in Nextion Editor 1.65'
  echo '  -tC    TFT Compile'
  echo '         HMI file in build is compiled to TFT file'
  echo '  -tD    TFT Server Deploy'
  echo '         TFT file is copied from build to HASS Server'
  echo '  -tO    TFT OTA (Over The Air) update'
  echo '         Device is triggered to perform a Nextion OTA update'
  echo '  -t     Performs HMI Build, Compile, Deploy and TFT OTA'
  echo '         Equivilant to flags [-tB -tC -tD -tO]'
}

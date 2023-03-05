#!/bin/bash

if [ $ESP_BUILD -eq 1 ]; then
  logger " "
  logger "ESP Build: Begin"
  #Set Version number
  device_build=$(calcFileVersion ${DIR_COMPONENT}/device-configuration.yaml)
  logger " - build.version  : ${device_build}"
  logger " - build.yaml     : $CFG_FILE -> $esphome_name.yaml"
  echo -e "$(eval "echo -e \"$(<$DIR_COMPONENT/substitutions.yaml)\"")" >$DIR_BUILD/$esphome_name.yaml
  cat $DIR_COMPONENT/device-configuration.yaml >>$DIR_BUILD/$esphome_name.yaml
  #Images to Build
  #Create Dashboard
  if [ -f $DIR_COMPONENT_DASHBOARD/device.yaml ]; then
    logger " - build.dashboard: $CFG_FILE+substitutions.yaml -> homeassistant/$esphome_name.dashboard"
    echo -e "$(eval "echo -e \"$(<$DIR_COMPONENT_DASHBOARD/device.yaml)\"")" >$DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml
  fi
  logger "ESP Build: Successful"
fi

if [ $ESP_COMPILE -eq 1 ]; then
  logger " "
  logger -s -i "ESP Compile: Begin"
  logger -s " - copy: ${esphome_name}.yaml -> ${DIR_ESPDEPLOY}"
  cp $DIR_BUILD/$esphome_name.yaml ${DIR_ESPDEPLOY}/ >/dev/null
  if [ $? -ne 0 ]; then
    logger -m "ESP Compile: Failed - Copy YAML from build to deploy"
    exit 1
  fi
  if [ -f $DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml ]; then
    logger -s " - copy: dashboards/${esphome_name}.yaml -> [HOMEASSISTANT]"
    cp $DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml //homeassistant/config/dashboards/device-testing
  fi

  logger -s " - compile: ${esphome_name}.yaml -> [device image]"
  ssh root@homeassistant /config/esphome/scripts/espCompile.sh $esphome_name.yaml 2>&1 | logger -s
  logger -sContains 'Successfully compiled program'
  if [ $? -ne 0 ]; then
    logger -m "ESP Compile: Failed - See $DEVICE_LOG"
    exit 1
  fi
  logger -m "ESP Compile: Successful"
fi

if [ $ESP_OTA -eq 1 ]; then
  logger " "
  logger "ESP OTA: Begin"
  DEVICE_IP=$(getDeviceIP ${device_name_lower})
  if [ $? -ne 0 ]; then
    logger "ESP OTA: Failed - Device Offline"
    exit 1
  fi
  if [ $DEVICE_DISPLAY -eq 1 ]; then
    callService ${device_name_lower}_device_upgrade
  fi
  logger " - esphome.ota: [device image] -> ${device_name_lower}.lan"
  ssh root@homeassistant /config/esphome/scripts/espOTA.sh $esphome_name.yaml 2>&1 | logger -s -i
  #Check For Success
  logger -sContains 'Successfully uploaded program'
  if [ $? -ne 0 ]; then
    logger -m "ESP OTA: Failed - Device Offline"
    exit 1
  fi
  logger -m " - device.restarting"
  waitForOffline ${device_name_lower}
  waitOnRestart ${device_name_lower}
  logger " - device.restarted"
  logger "ESP OTA: Successful"
fi

if [ $TFT_OTA -eq 1 ]; then
  logger "TFT OTA: Begin"
  DEVICE_IP=$(getDeviceIP ${device_name_lower})
  if [ $? -ne 0 ]; then
    logger "TFT OTA: Failed - Device Offline"
    exit 1
  fi
  LOCAL_FILE="$DIR_COMPONENT_TFT/${nextion_file}.tft"
  DEPLOY_FILE="//homeassistant/config/www/nspanel/${nextion_file}.tft"
  if [ ! -f $DEPLOY_FILE ]; then
    logger " - nextion.deploy: [nextion image].tft -> [Web Server]"
    cp $LOCAL_FILE $DEPLOY_FILE
  else
    diff $LOCAL_FILE $DEPLOY_FILE >/dev/null
    if [ $? -eq 1 ]; then
      logger " - nextion.deploy: build/[nextion image].tft is newer version"
      logger " - nextion.deploy: [nextion image].tft -> [Web Server]"
      cp $LOCAL_FILE $DEPLOY_FILE
    else
      logger " - nextion.deploy: [nextion image].tft in sync with [Web Server]"
    fi
  fi
  logger " - nextion.ota: [nextion image].tft -> ${device_name_lower}.local"
  callService ${device_name_lower}_upload_tft
  if [ $? -ne 0 ]; then
    logger "TFT OTA: Failed - Device Offline"
    exit 1
  fi
  logger " - device.restarting"
  if [ $TFT_OTA_WAIT -eq 1 ]; then
    waitOnRestart ${device_name_lower}
    logger " - device.restarted"
    logger "TFT OTA: Successful"
  else
    logger "TFT OTA: Submitted Request, NO_WAIT requested"
  fi
fi

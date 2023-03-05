#!/bin/bash


if [ $ESP_BUILD -eq 1 ]; then
  logD " "
  logD "ESP Build: Begin"
  #Set Version number
  device_build=$(calcFileVersion ${DIR_COMPONENT}/device-configuration.yaml)
  logD " - build.version  : ${device_build}"
  logD " - build.yaml     : $CFG_FILE -> $esphome_name.yaml"
  echo -e "$(eval "echo -e \"$(<$DIR_COMPONENT/substitutions.yaml)\"")" >$DIR_BUILD/$esphome_name.yaml
  cat $DIR_COMPONENT/device-configuration.yaml >>$DIR_BUILD/$esphome_name.yaml
  #Images to Build
  #Create Dashboard
  if [ -f $DIR_COMPONENT_DASHBOARD/device.yaml ]; then
    logD " - build.dashboard: $CFG_FILE+substitutions.yaml -> homeassistant/$esphome_name.dashboard"
    echo -e "$(eval "echo -e \"$(<$DIR_COMPONENT_DASHBOARD/device.yaml)\"")" >$DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml
  fi
  logD "ESP Build: Successful"
fi

if [ $ESP_COMPILE -eq 1 ]; then
  logD " "
  logS -i "ESP Compile: Begin"
  logS " - copy: ${esphome_name}.yaml -> ${DIR_ESPDEPLOY}"
  cp $DIR_BUILD/$esphome_name.yaml ${DIR_ESPDEPLOY}/ >/dev/null
  if [ $? -ne 0 ]; then
    logD -m "ESP Compile: Failed - Copy YAML from build to deploy"
    exit 1
  fi
  if [ -f $DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml ]; then
    logS " - copy: dashboards/${esphome_name}.yaml -> [HOMEASSISTANT]"
    cp $DIR_BUILD/../homeassistant/dashboards/$esphome_name.yaml //homeassistant/config/dashboards/device-testing
  fi

  logS " - compile: ${esphome_name}.yaml -> [device image]"
  ssh root@homeassistant /config/esphome/scripts/espCompile.sh $esphome_name.yaml 2>&1 | logS
  logSContains 'Successfully compiled program'
  if [ $? -ne 0 ]; then
    logD -m "ESP Compile: Failed - See $DEVICE_LOG"
    exit 1
  fi
  logD -m "ESP Compile: Successful"
fi

if [ $ESP_OTA -eq 1 ]; then
  logD " "
  logD "ESP OTA: Begin"
  DEVICE_IP=$(getDeviceIP ${device_name_lower})
  if [ $? -ne 0 ]; then
    logD "ESP OTA: Failed - Device Offline"
    exit 1
  fi
  if [ $DEVICE_DISPLAY -eq 1 ]; then
    callService ${device_name_lower}_device_upgrade
  fi
  logD " - esphome.ota: [device image] -> ${device_name_lower}.lan"
  ssh root@homeassistant /config/esphome/scripts/espOTA.sh $esphome_name.yaml 2>&1 | logS -i
  #Check For Success
  logSContains 'Successfully uploaded program'
  if [ $? -ne 0 ]; then
    logD -m "ESP OTA: Failed - Device Offline"
    exit 1
  fi
  logD -m " - device.restarting"
  waitForOffline ${device_name_lower}
  waitOnRestart ${device_name_lower}
  logD " - device.restarted"
  logD "ESP OTA: Successful"
fi

if [ $TFT_OTA -eq 1 ]; then
  logD "TFT OTA: Begin"
  DEVICE_IP=$(getDeviceIP ${device_name_lower})
  if [ $? -ne 0 ]; then
    logD "TFT OTA: Failed - Device Offline"
    exit 1
  fi
  LOCAL_FILE="$DIR_COMPONENT_TFT/${nextion_file}.tft"
  DEPLOY_FILE="//homeassistant/config/www/nspanel/${nextion_file}.tft"
  if [ ! -f $DEPLOY_FILE ]; then
    logD " - nextion.deploy: [nextion image].tft -> [Web Server]"
    cp $LOCAL_FILE $DEPLOY_FILE
  else
    diff $LOCAL_FILE $DEPLOY_FILE >/dev/null
    if [ $? -eq 1 ]; then
      logD " - nextion.deploy: build/[nextion image].tft is newer version"
      logD " - nextion.deploy: [nextion image].tft -> [Web Server]"
      cp $LOCAL_FILE $DEPLOY_FILE
    else
      logD " - nextion.deploy: [nextion image].tft in sync with [Web Server]"
    fi
  fi
  logD " - nextion.ota: [nextion image].tft -> ${device_name_lower}.local"
  callService ${device_name_lower}_upload_tft
  if [ $? -ne 0 ]; then
    logD "TFT OTA: Failed - Device Offline"
    exit 1
  fi
  logD " - device.restarting"
  if [ $TFT_OTA_WAIT -eq 1 ]; then
    waitOnRestart ${device_name_lower}
    logD " - device.restarted"
    logD "TFT OTA: Successful"
  else
    logD "TFT OTA: Submitted Request, NO_WAIT requested"
  fi
fi

#!/bin/bash

clear

# Locate Base Path
cd `dirname $0`/..
DIR_BASE="${PWD}"

# Setup required environment variables
## Paths
DIR_BIN="$DIR_BASE/bin"

DIR_BUILD="$DIR_BASE/build"
DIR_BUILD_LOGS="$DIR_BUILD/logs"
DIR_BUILD_TEMP="$DIR_BUILD/temp"
DIR_BUILD_ESPHOME="$DIR_BUILD/esphome"
DIR_BUILD_NEXTION="$DIR_BUILD/nextion"
DIR_BUILD_DASHBOARD="$DIR_BUILD/homeassistant/dashboards"
DIR_BUILD_CARD="$DIR_BUILD/homeassistant/cards"
DIR_BUILD_SENSOR="$DIR_BUILD/homeassistant/sensors"

DIR_CONFIG="$DIR_BASE/config"
DIR_COMPONENT="$DIR_BASE/components"

DIR_DEPLOY="//homeassistant/config"
DIR_DEPLOY_ESPHOME="${DIR_DEPLOY}/esphome"
DIR_DEPLOY_NEXTION="${DIR_DEPLOY}/www/nextion"
DIR_DEPLOY_DASHBOARD="${DIR_DEPLOY}/include/dashboards"


# Set default Flags
DEVICE_WAIT_FOR_READY=0
DEVICE_HAS_DISPLAY=0

ESP_BUILD=0
ESP_COMPILE=0
ESP_OTA=0
ESP_RESTART=0

HA_BUILD=0
HA_DEPLOY=0
HA_RELOAD_CONFIG=0
HA_RESTART=0

TFT_BUILD=0
TFT_COMPILE=0
TFT_OTA=0
TFT_OTA_WAIT=1
TFT_RESTART=0

# Import functions
. ${DIR_BIN}/functions/func_Usage.sh
. ${DIR_BIN}/functions/func_Version.sh
. ${DIR_BIN}/functions/func_Logs.sh
. ${DIR_BIN}/functions/func_HomeAssistant.sh
. ${DIR_BIN}/functions/func_Device.sh
. ${DIR_BIN}/functions/func_Yaml.sh
. ${DIR_BIN}/functions/func_EspBuild.sh


# Verify we have Args
if [ $# -eq 0 ]; then
  usage "Error: No Arguments specified."
  exit 1
fi

# Parse Flags and save CONFIG entries
CONFIG_ENTRY={}
let CONFIG_ENTRY_CNT=0
while [ -n "$1" ]
do
    case "$1" in
        -n) TFT_OTA_WAIT=0;;
        -w) WAIT_READY=1;;
        # ESP Parameters
        -e) ESP_BUILD=1
            ESP_COMPILE=1
            ESP_OTA=1;; 
        -eB) ESP_BUILD=1;;
        -eC) ESP_COMPILE=1;;
        -eO) ESP_OTA=1;;
        -eD) ESP_OTA=1;;
        # HMI/TFT Parameters
        -t) TFT_BUILD=1
            TFT_COMPILE=1
            TFT_OTA=1;;
        -tB) TFT_BUILD=1;;
        -tC) TFT_COMPILE=1;;
        -tO) TFT_OTA=1;;
        -tD) TFT_OTA=1;;
        # Process Config file
        *) 
          if [ "`echo $1 | cut -c1`" == '-' ];then
            usage "Unknown Switch:  $1"
            exit 1
          fi
          CONFIG_ENTRY[${CONFIG_ENTRY_CNT}]=$1
          let CONFIG_ENTRY_CNT=CONFIG_ENTRY_CNT+1
        ;;
    esac
    shift
done

echo "Cleaning Build Directory"
rm -rf ${DIR_BUILD}
for d in $(set | grep "DIR_BUILD" | cut -f2 -d'='); do
  mkdir -p $d
done

echo "$CONFIG_ENTRY_CNT configuration files submitted: "
for i in "${CONFIG_ENTRY[@]}"
do
  CONFIG_FILE=$(find $DIR_CONFIG | grep $i | grep yaml)
  if [ ! -z $CONFIG_FILE ];then
	  echo "--Processing: $CONFIG_FILE"
    eval $(parse_yaml $CONFIG_FILE cfg_ )

    # Set the Component specific directories
    DIR_COMPONENT_ESPHOME="${DIR_COMPONENT}/${cfg_component_type}/esphome"
    DIR_COMPONENT_DASHBOARD="${DIR_COMPONENT}/${cfg_component_type}/homeassistant/dashboard"
    DIR_COMPONENT_CARD="${DIR_COMPONENT}/${cfg_component_type}/homeassistant/card"
    DIR_COMPONENT_NEXTION="${DIR_COMPONENT}/${cfg_component_type}/nextion"

    if [ ! -z $cfg_nextion_name ];then
      echo "--Loading Nextion configuration"
      eval $(parse_yaml ${DIR_COMPONENT_NEXTION}/${cfg_nextion_name}.yaml cfg_ )
    fi

    # Reload Lookups
    eval $(parse_yaml ${DIR_CONFIG}/lookups/names-ip.yaml  )
    eval $(parse_yaml ${DIR_CONFIG}/lookups/names-ota-password.yaml )

    # Setup defaults and overrides
    # DEVICE_IP
    if [ -z "$cfg_device_ip" ];then
      cfg_device_ip=DHCP
    else
      if [ "$cfg_device_ip" == "NAMES_IP" ];then
        cfg_tst_var="names_ip_${cfg_device_name}"
        if [ -n "${!cfg_tst_var}" ];then
            cfg_device_ip="${!cfg_tst_var}"
        fi
      fi
    fi

    # ESPHOME_FILENAME
    # default filename: ${cfg_component_type}_${cfg_device_name}.yaml
    if [ -z "$cfg_esphome_filename" ];then
        cfg_esphome_filename="${cfg_component_type,,}_${cfg_device_name,,}.yaml"
    fi

    # ESPHOME_OTA_PASSWORD
    if [ -z "$cfg_esphome_ota_password" ];then
      cfg_esphome_ota_password=NAMES_OTA
    fi

    if [ "$cfg_esphome_ota_password" == "NAMES_OTA" ];then
        cfg_tst_var="names_ota_password_${cfg_device_name,,}"
        if [ -n "${!cfg_tst_var}" ];then
          cfg_esphome_ota_password="${!cfg_tst_var}"
        else
          cfg_esphome_ota_password=DEFAULT
        fi
    fi

    if [ "$cfg_esphome_ota_password" == "DEFAULT" ];then
        cfg_tst_var="names_ota_password_default"
        if [ -n "${!cfg_tst_var}" ];then
          cfg_esphome_ota_password="${!cfg_tst_var}"
        else
          echo "Failed to set default OTA Password. Please check names-ota-password.yaml file."
          #exit 1
        fi
    fi

    # Write base config to the logs    
    logger -i -f $DIR_BUILD_LOGS/${cfg_device_name,,}.log
    logger -d 
    logger "-- `basename $0` Config settings" 
    logger -d 
    logger "LOGS DIRECTORY          : $DIR_BUILD_LOGS" 
    logger "TEMP DIRECTORY          : $DIR_BUILD_TEMP" 
    logger -d 
    logger "ESPHOME"
    logger "  COMPONENT DIRECTORY   : $DIR_BUILD_DASHBOARD" 
    logger "  BUILD DIRECTORY       : $DIR_BUILD_ESPHOME" 
    logger "  DEPLOY DIRECTORY      : $DIR_DEPLOY_ESPHOME" 
    logger -d 
    logger "NEXTION"
    logger "  COMPONENT DIRECTORY   : $DIR_COMPONENT_NEXTION" 
    logger "  BUILD DIRECTORY       : $DIR_BUILD_NEXTION" 
    logger "  DEPLOY DIRECTORY      : $DIR_DEPLOY_NEXTION" 
    logger -d 
    logger "HOMEASSISTANT"
    logger "  DASHBOARD"
    logger "    COMPONENT DIRECTORY : $DIR_COMPONENT_DASHBOARD" 
    logger "    BUILD DIRECTORY     : $DIR_BUILD_DASHBOARD" 
    logger "    DEPLOY DIRECTORY    : $DIR_DEPLOY_DASHBOARD" 
    logger "  CARD"
    logger "    COMPONENT DIRECTORY : $DIR_COMPONENT_CARD" 
    logger "    BUILD DIRECTORY     : $DIR_BUILD_CARD" 
    logger "  SENSOR"
    logger "    BUILD DIRECTORY     : $DIR_BUILD_SENSOR" 
    logger -d 

    set > /c/development/VSCode/vcodegen/bin/env_vars.sh
    #build_Esp $DIR_COMPONENT_ESPHOME/$cfg_component_name.yaml $DIR_BUILD_ESPHOME/$cfg_esphome_filename
  else
    echo "--Missing Configuration: $i"
  fi
done
exit 1

          # #If any OTA is planned, and the device has a display, then switch device to upgrade mode
          # if [ $DEVICE_DISPLAY -eq 1 ];then
          #   if [ $ESP_OTA -eq 1 ]; then
          #       callService ${device_name_lower}_device_upgrade 
          #   fi
          #   if [ $TFT_OTA -eq 1 ]; then
          #       callService ${device_name_lower}_device_upgrade
          #   fi
          # fi

          # if [ $WAIT_READY -eq 1 ]; then
          #   logger "Waiting on Device Ready"   
          #   waitOnRestart ${device_name_lower}         
          # fi

          logger "Requested Operations: Successful" 


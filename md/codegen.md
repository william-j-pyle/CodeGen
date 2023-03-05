# CodeGen

```
Usage: codegen [flags] {device-config file(s)}
  -a     Performs Dashboard, ESP, and TFT Builds and Deploys
  -d     Dashboard Build and Deploy
         Equivilant to flags [ -dB -dD]
  -dB    Dashboard Build
         Home Assistant Dashboard YAML is built into build directory
  -dD    Dashboard Deploy
         Deploy Dashboard YAML to Home Assistant
         Performs service call to refresh
  -eB    ESP Build
         YAML file is generated into build directory
  -eC    ESP Compile
         YAML file is copied from build to HASS Server
         ESPHome is triggered to compile YAML file
  -eO    ESP OTA (Over The Air) update
         IP Address is determined for device
         OTA update is performed by ESPHome to device
  -e     Performs ESP Build, Compile, and OTA
         Equivilant to flags [-eB -eC -eO]
  -tB    HMI Build
         Fonts are processed into Nextion format, placed in build
         Images are processed into Nextion format, placed in build
         HMI(TFT Source file) is generated into build
         ** Resulting HMI can be edited in Nextion Editor 1.65
  -tC    TFT Compile
         HMI file in build is compiled to TFT file
  -tD    TFT Server Deploy
         TFT file is copied from build to HASS Server
  -tO    TFT OTA (Over The Air) update
         Device is triggered to perform a Nextion OTA update
  -t     Performs HMI Build, Compile, Deploy and TFT OTA
         Equivilant to flags [-tB -tC -tD -tO]
```

## How user device configuration is processed

The Yaml configuration is converted to bash variables via collapsing the hierarchy into variables with underscore '_' as the seperator.

This is done via a call to [parse_yaml](parse_yaml.md).

Once the Yaml has been turned into bash variables, the following variables are directly required to determine what occurs next:

| Variable | Description |
| -------- | ----------- |
| cfg_device_type | This defines which Library contains the device definition |
| cfg_device_config | This defines which device configuration is utilized in the device definition |

## Loading Device Configuration

Each Yaml file passed to codegen is processed serially.
Each file is:

* loaded
* converted to bash variables
* then the requested device config.yaml is loaded
* then its converted to bash variables
* 

> Example: **src/nspanel/nspanel0001-office.yaml**

``` yaml
room: 
  name: Office

device:
  type: nspanel
  config: home-default
  name: nspanel0001
  friendly_name: ${cfg_room_name}
  description: ${cfg_room_name}
  ```

This file will tell us where to look for the device's config.yaml

``` bash
BASE_LIB_CONFIG_DIR=${BASE_DIR}/lib/${cfg_device_type}/${cfg_device_config}
BASE_LIB_CONFIG=${BASE_LIB_CONFIG_DIR}/config.yaml
```

This YAML file defines the individual components that are part of this devices configuration.

```yaml
components:
  - type: ESPHOME
    config: esphome.yaml
    require: NEXTION
  - type: DASHBOARD
    config: dashboard.yaml
    require: ESPHOME
  - type: NEXTION
    config: nextion.yaml
```

* TYPE - Identifies which cbd functions to use
* CONFIG - Identifies the yaml file to pass to the CBD
* REQUIRE - Optional field indicating a component TYPE that must be loaded prior to processing this config.  

## CBD: ESPHOME

***Clean***

* Removes ```${BASE_DIR}/build/${cfg_device_name}/esphome```
* Performs a remote clean on ESPHome

***Build***

The Build process for ESPHome is 2 fold, it will build the YAML required for ESPHome, then remotely call ESPHome to build the device image.  When ESPHome has completed building the device image, its copied back to the local build directory.

* Executes ***Clean***
* Creates ```${BASE_DIR}/build/${cfg_device_name}/esphome```
* Processes config then generates and builds required files to ```${BASE_DIR}/build/${cfg_device_name}/esphome```

***Deploy***

* If ! Exists ```${BASE_DIR}/build/${cfg_device_name}/esphome```
  * Executes ***Build***
* Compares local build to ESPHomes build, if ! match:
  * Executes ***Build***
* Performs ***OTA Update***

### CBD: DASHBOARD

***Clean***

* Removes ```${BASE_DIR}/build/${cfg_device_name}/dashboard```

***Build***

* Executes ***Clean***
* Creates ```${BASE_DIR}/build/${cfg_device_name}/dashboard```
* Processes config then generates and builds required files to ```${BASE_DIR}/build/${cfg_device_name}/dashboard```

***Deploy***

* If ! Exists ```${BASE_DIR}/build/${cfg_device_name}/dashboard```
  * Executes ***Build***
* Deploys YAML and supporting files to HomeAssistant Config
* Performs Service call for HASS to reload configuration

### CBD: NEXTION

***Clean***

* Removes ```${BASE_DIR}/build/${cfg_device_name}/nextion```

***Build***

* Executes ***Clean***
* Creates ```${BASE_DIR}/build/${cfg_device_name}/nextion```
* Processes config
* Generates:
  * required fonts
  * required images
  * hmi file
* Compiles HMI to TFT

***Deploy***

* If ! Exists ```${BASE_DIR}/build/${cfg_device_name}/nextion```
  * Executes ***Build***
* Deploys TFT file to OTA Server
* Performs Service call instructing device to Update the Nextion firmware

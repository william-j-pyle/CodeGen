# YAMLScript

```bash
  yamlscript <yaml file>
```

YAMLScript is an embedded processing language to assist in dynamically modifying YAML files.  When configuration files are being dynamically generated via build processes, its much easier to have a full copy of the YAML then selectivly turn off sections of the configuration, than to just dynamically generate the entire file via code or concatenation.

**Quick Example**

***BASH Variables***

```bash
device_name=NSPanel-Living-Room
device_room=Living Room
cfg_enable_ap=1
cfg_enable_web_server=0
cfg_enable_logger=1
cfg_log_level=DEBUG
cfg_esp_globals_cnt=2
cfg_esp_globals_name[1]=device_active
cfg_esp_globals_type[1]=boolean
cfg_esp_globals_restore[1]=false
cfg_esp_globals_init_value[1]=false
cfg_esp_globals_name[2]=device_counter
cfg_esp_globals_restore[2]=true
cfg_esp_globals_init_value[2]=0
```

***YAML***

```yaml
#!yamlscript:1.0
esphome:
  name: ${device_name,,}
  comment: $device_room

esp32:
  board: esp32dev

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  fast_connect: true
#@if $cfg_enable_ap == 1
  ap:
    ssid: $device_name
    password: !secret fallback_password
#@fi

#@if $cfg_enable_web_server == 1
web_server:
  port: 80  
#@fi

#@if $cfg_enable_logger == 1
logger:
  level: $cfg_log_level
#@fi

globals:
#@for i = 1 to $cfg_esp_globals_cnt
#@@if def $cfg_esp_globals_name[i] 
  - id: $cfg_esp_globals_name[i]
#@@@if def $cfg_esp_globals_type[i]
    type: $cfg_esp_globals_type[i]
#@@@else
    type: int
#@@@fi
    restore_value: $cfg_esp_globals_restore[i]
    initial_value: '$cfg_esp_globals_init_value[i]'
#@@fi
#@next
```

***Processed YAML***

```yaml
esphome:
  name: nspanel-living-room
  comment: Living Room

esp32:
  board: esp32dev

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  fast_connect: true
  ap:
    ssid: NSPanel-Living-Room
    password: !secret fallback_password


logger:
  level: DEBUG

globals:
  - id: device_active
    type: boolean
    restore_value: false
    initial_value: 'false'
  - id: device_counter
    type: int
    restore_value: true
    initial_value: '0'
```

As you can see, the syntax is very simplistic, but allows you to achieve a lot.

| Statement | Description | 
| --------- | ----------- | 
| if var1 operator var2 | IF statement code block, supports ELSE, and closes with FI. When evaluates to true then code between if and else (or fi if else is not preset) is evaluated |
| else | Part of IF statement, code block that is executed when IF is False |
| fi | Ends an IF statement code block |
| for var = # to # | Performs a simple loop, the code block inside the for/next will be evaluated N times depending on the numbers given. Inside the code block you will have access to 4 variables, see FOR CODE BLOCK VARIABLES below|
| next | Ends a For statement code block |
| include {filename} {indent}| will import an external file into document, optionally you can also specify the indentention level and the imported yaml will be adjusted to that level|
| define var=value | allows you to define a varible and give it a value |
| default var=value | if the variable is already set to a value, nothing will happen, if the variable is not set, then it will be defaulted to this value |
| exec {scriptname} | allows execution of an external script. All parameters given after scriptname are pasted to that script.  Upon success/failure of script, the variable exec_state will be set to 1-fail or 0-success.  Also exec_result will contain the stdout. |

***FOR CODE BLOCK VARIABLES***

| Variable | Description |
| -------- | ----------- |
| {var}    | Variable defined in for statement |
| {var}_low| The starting value in the for statement |
| {var}_high| The ending value in the for statement |
| {var}_loops | The number of loops the for statement will perform (high-low) |
| {var}_idx | Where var will increment from low to high, {var}_idx will increment from 1 to {var}_loops |
| {var}_isfirst | 1-true, 0-false, evaluates if this is 1st loop {var}_idx=1|
| {var}_islast | 1-true, 0-false, evaluates if this is last loop {var}_idx={var}_loops|

***IF Comparison Types***

| Comparator | Description |
| -------- | ----------- |
| eq       | equals      |
| gt       | greater than|
| ge       | greater than or equal too, alias for !lt |
| lt       | less than   |
| le       | less than or equal too, alias for !gt |
| defined  | variable is set |
| exists   | file exists |
| zerolen  | variable has zero length |

Placing a '!' in front of a Comparator performs a NOT.
For example: eq is equals and !eq is not equals



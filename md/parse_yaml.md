# Parse_YAML

```
parse_yaml <YAML filename> <optional variable prefix>
```

Parse_yaml returns the BASH created variables via STDOUT.
Then it can be redirected to another file, or evaluated.

### Example

``` bash
YAML_FILE=test.yaml
VAR_PREFIX=cfg_
# Return variables to STDOUT
parse_yaml $YAML_FILE $VAR_PREFIX
# Evaluate variables into current shell
eval $(parse_yaml $YAML_FILE $VAR_PREFIX )
```

**test.yaml**
``` yaml
key1:
  key11: value
  key12: value2
  key13:
    key131: value3
    key132: value4
```

**STDOUT**

``` bash
cfg_key1_key11=value
cfg_key1_key12=value2
cfg_key1_key13_key131=value3
cfg_key1_key13_key132=value4
```

The ```VAR_PREFIX``` was prefixed on each variable name.
No variables were generated for ```key1``` and ```key13``` because they have no value.

### Example 2

Data is not always represented as objects, you also have arrays. 

**test.yaml**

``` yaml
nextion:
  backgrounds:
    - name: Default
      id: 0
      pic_id: 1
      filename: bg_default.jpg
    - name: Default - Eleanor
      id: 1
      pic_id: 179
      filename: bg_default_2.jpg
```

**STDOUT**

``` bash
cfg_nextion_backgrounds_count=2
cfg_nextion_backgrounds_filename=([1]="bg_default.jpg" [2]="bg_default_2.jpg")
cfg_nextion_backgrounds_id=([1]="0" [2]="1")
cfg_nextion_backgrounds_name=([1]="Default" [2]="Default - Eleanor")
cfg_nextion_backgrounds_pic_id=([1]="1" [2]="179")
```

While not necessarily the most elegant way to present the data, it is effective and works.

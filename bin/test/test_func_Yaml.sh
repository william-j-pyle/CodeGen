#!/bin/bash

. ../functions/func_Yaml.sh
 
TEST_YAML=test_func_Yaml.yaml
TEST_PREFIX=test_func_Yaml_


eval $(parse_yaml $TEST_YAML $TEST_PREFIX )

echo "Source YAML"
cat $TEST_YAML
echo " "
echo "Parse Results"
set | grep $TEST_PREFIX | grep -v '_=' | grep -v whatever


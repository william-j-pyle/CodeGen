#!/bin/bash

TEST_FILE=../../components/nspanel/esphome/nspanel-standard.yaml

sed 's/${page_main_name}/JAZCOPAGE/g' $TEST_FILE |
sed 's/$state_awake/1/g'
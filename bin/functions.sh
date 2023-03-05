#!/bin/bash

if [ -z ${BIN_DIR} ]; then
    echo "Environment Variable 'BIN_DIR' not set."
    exit 1
fi

. ${BIN_DIR}/functions/codegen_usage.sh
. ${BIN_DIR}/functions/codegen_logs.sh
. ${BIN_DIR}/functions/codegen_yaml.sh
. ${BIN_DIR}/functions/codegen_version.sh
. ${BIN_DIR}/functions/codegen_device.sh
. ${BIN_DIR}/functions/hass_services.sh

# Clean Build Deploy
#. ${BIN_DIR}/functions/cbd_dashboard.sh
. ${BIN_DIR}/functions/cbd_esphome.sh
. ${BIN_DIR}/functions/cbd_nextion.sh

#!/bin/bash


function build_Esp() {
    if [ $ESP_BUILD -eq 1 ]; then
        local CONFIG_FILE=$1
        local BUILD_FILE=$2
        logger " "
        logger "ESP Build: Begin"
        #Set Version number
        device_build=$(calcFileVersion ${CONFIG_FILE})
        logger " - build.version  : ${device_build}"
        logger " - build.yaml     : $(basename $CONFIG_FILE) -> $(basename $BUILD_FILE)"

        echo -e "$(eval "echo -e \"$(<${CONFIG_FILE})\"")" >$BUILD_FILE
        logger "ESP Build: Successful"
    fi
}

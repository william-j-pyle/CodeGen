#!/bin/bash

function getDeviceIP() {
    IP=$(nslookup $1 2>/dev/null | grep -v 192.168.86.1 | grep 192.168.86 | cut -c11-)
    if [ -n "$IP" ]; then
        echo $IP
        return 0
    fi
    return 1
}

#!/bin/bash

HA_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJmNjNjNjA0ZDRjYTA0NjViOWViYTlmMGE2YmE3NjI3NyIsImlhdCI6MTY3MDk2MTYzNiwiZXhwIjoxOTg2MzIxNjM2fQ.yIFVzqsKezDHF3dtftMS2AwnzywaPsiwIwm_et6GbeY"
HA_URL="http://homeassistant:8123"
HA_API="${HA_URL}/api"

function callService() {
  RTN=0
  SERVICE_LOG=$DIR_BUILD_LOGS/callService.${1}.log
  curl -X POST ${HA_API}/services/esphome/${1} -H "Authorization: Bearer ${HA_TOKEN}" >$SERVICE_LOG 2>&1
  grep '[[]]' ${SERVICE_LOG} >/dev/null
  RTN=$?
  rm -f $SERVICE_LOG
  return $RTN
}

function waitOnRestart() {
  CONT=1
  while [ $CONT -ne 0 ]; do
    sleep 2
    callService ${1}_device_available
    CONT=$?
  done
}

function waitForOffline() {
  CONT=0
  while [ $CONT -eq 0 ]; do
    sleep 2
    callService ${1}_device_available
    CONT=$?
  done
}

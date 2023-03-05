#!/bin/bash

LOG_FILENAME=""

function logSContains() {
   RTN=0
   grep "$1" ${DEVICE_LOG}.STEP >/dev/null 2>&1
   RTN=$?
   return $RTN
}

function logger() {
   local DO_CLEAR=0
   local DO_LINE=""
   local DO_STDIN=0
   local ACTIVE_LOG_FILENAME=$LOG_FILENAME
   for i in "${@}"; do
      if [ "$i" == "-d" ]; then
         shift
         DO_LINE=""
         for i in {1..55}; do
            DO_LINE="${DO_LINE}-"
         done
      fi
      if [ "$i" == "-f" ]; then
         shift
         LOG_FILENAME=$1
         ACTIVE_LOG_FILENAME=$LOG_FILENAME
         shift
      fi
      if [ "$i" == "-stdin" ]; then
         shift
         DO_STDIN=1
      fi
      if [ "$i" == "-pipe" ]; then
         shift
         DO_STDIN=1
      fi
      if [ "$1" == "-i" ]; then
         if [ -f $ACTIVE_LOG_FILENAME ]; then
            DO_CLEAR=1
         fi
         shift
      fi
      if [ "$1" == "-s" ]; then
         ACTIVE_LOG_FILENAME=${LOG_FILENAME}.STEP
         shift
      fi
      if [ "$1" == "-m" ]; then
         if [ -f "${ACTIVE_LOG_FILENAME}.STEP" ]; then
            cat ${ACTIVE_LOG_FILENAME}.STEP >>${ACTIVE_LOG_FILENAME}
            rm -f ${ACTIVE_LOG_FILENAME}.STEP >/dev/null 2>&1
         fi
         shift
      fi
      if [ "$1" == "-c" ]; then
         if [ -f "${ACTIVE_LOG_FILENAME}.STEP" ]; then
            grep "$2" ${ACTIVE_LOG_FILENAME}.STEP >/dev/null 2>&1
            return $?
         else
            return 1
         fi
      fi
   done

   if [ $DO_CLEAR -eq 1 ]; then
      rm -f ${ACTIVE_LOG_FILENAME} >/dev/null 2>&1
   fi

   if [ ! -z $DO_LINE ]; then
      echo "$(date +'%Y%m%d-%H%M%S'): $DO_LINE" | tee -a ${ACTIVE_LOG_FILENAME}
   fi

   if [ -n "$1" ]; then
      echo "$(date +'%Y%m%d-%H%M%S'): $1" | tee -a ${ACTIVE_LOG_FILENAME}
   fi
   if [ $DO_STDIN -eq 1 ]; then
      while read -r LINE; do
         echo "$(date +'%Y%m%d-%H%M%S'): $LINE" | tee -a ${ACTIVE_LOG_FILENAME}
      done
   fi
}

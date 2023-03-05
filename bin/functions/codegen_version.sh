#!/bin/bash

function writeVersion() {
  date +'%Y%m%d-%H%M%S' >${DIR_COMPONENT}/version.txt
}

function updateVersion() {
  CHK=$(basename $1)
  if [ ! -f ${DIR_COMPONENT}/.${CHK} ]; then
    cp ${DIR_COMPONENT}/${CHK} ${DIR_COMPONENT}/.${CHK}
  fi
  diff ${DIR_COMPONENT}/${CHK} ${DIR_COMPONENT}/.${CHK} >/dev/null
  if [ $? -eq 1 ]; then
    writeVersion
  fi
}

function getVersion() {
  while [ -n "$1" ]; do
    updateVersion $1
    shift
  done
  if [ ! -f ${DIR_COMPONENT}/version.txt ]; then
    writeVersion
  fi
  cat ${DIR_COMPONENT}/version.txt
}

function calcFileVersion() {
  if [ ! -f $1 ]; then
    echo "Error locating file: $1"
    exit 1
  fi
  pwd=$PWD
  cd $(dirname $1)
  FILE=$(ls -l $1)
  MONTHS=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
  C=$(echo $FILE | sed -r 's/[ ]+/,/g')
  MON=$(echo $C | cut -f6 -d,)
  for i in ${!MONTHS[@]}; do
    if [ "$MON" == "${MONTHS[$i]}" ]; then
      let MO=$i+1
    fi
  done
  D=$(echo $C | cut -f7 -d,)
  HorY=$(echo $C | cut -f8 -d,)
  H=0
  M=0
  Y=0
  if [ $(echo $HorY | cut -c3) == ":" ]; then
    X=$(echo $HorY | cut -f1 -d:)
    H="1$X"
    X=$(echo $HorY | cut -f2 -d:)
    M="1$X"
    Y=$(date +'%Y')
  else
    let H=123
    let M=159
    Y=$HorY
  fi
  let H=H-100
  let M=M-100
  let V=H*3600
  let V=V+M*60
  printf "%.4i.%.2i.%.2i.%.5i" $Y $MO $D $V
  cd $pwd
}

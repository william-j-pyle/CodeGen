#!/bin/bash

. ../functions/func_Logs.sh
 
logger -i -f test_func_Logs.log "Create New TEST.log file"
logger "WRITE LINE 2"
logger "WRITE LINE 3"
logger -s -i "Create new STEP file (TEST.log.STEP)"
logger -s "LINE 2 of STEP"
logger -s "Does STEP contain [B O G U S]"
logger -s -d
logger -c "BOGUS"
x=$?
if [ $x -eq 0 ];then 
  logger -s "FOUND BOGUS"
else
  logger -s "NO BOGUS"
fi
logger -m "Merged down the step"
logger -d
logger -s -i "Create another new STEP File"
logger -s "This has a BOGUS Word to find"
logger -s "Does STEP contain BOGUS"
logger -c "BOGUS"
x=$?
if [ $x -eq 0 ];then 
  logger -s "FOUND BOGUS"
else
  logger -s "NO BOGUS"
fi
logger -m "Merge step back into main"
logger "Standard IN test"
ls -l | logger -stdin
logger "we are all done"

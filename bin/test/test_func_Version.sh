#!/bin/bash

. ../functions/func_Version.sh

TEST_FILE_1=../functions/func_Version.sh
TEST_FILE_2=$0

echo "TEST_1"
ls -l $TEST_FILE_1
echo " "
echo "VERSION: "`calcFileVersion ${TEST_FILE_1}`
echo " "
echo " "
echo "TEST_2"
ls -l $TEST_FILE_2
echo " "
echo "VERSION: "`calcFileVersion ${TEST_FILE_2}`

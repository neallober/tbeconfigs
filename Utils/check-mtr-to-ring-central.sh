#!/bin/bash

echo "Starting script, please wait..."
STARTING_DATESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
RESULT=$(/opt/local/sbin/mtr --report --report-cycle 120 sip.ringcentral.com)
echo "Finished MTR, writing results to file..."
ENDING_DATESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
FILE="/Users/neallober/mtr-results.txt"

echo "" >> $FILE
echo "============================================================================" >> $FILE
echo " MTR to sip.ringcentral.com " >> $FILE
echo "============================================================================" >> $FILE
echo " Started: $STARTING_DATESTAMP  " >> $FILE
echo " Ended:   $ENDING_DATESTAMP  " >> $FILE
echo "............................................................................" >> $FILE
echo "$RESULT" >> $FILE
echo "............................................................................" >> $FILE

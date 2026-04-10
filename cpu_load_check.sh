#Author: Sahil Sharma
#About: This script checks the cpu load average for 5 minutes and warns if it goes beyond a certain level given by user. 
#It can be improved with email functionality and can be run using as cronjob
#KeyPoints: how to handle decimal values
#	    how to get the required information from command outputs using different tools like cut awk sed
#Need to provide command line args

#!/bin/bash
LOAD=`uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $2}' | sed 's/ //g'` #getting the load value from uptime
if [ -z "$1" ]
then
	echo "Please provide a argument with script"
	echo "Example: bash $0 2"
	exit 1
else
	LIMIT="$1"
fi
if [ `echo "$LOAD > $LIMIT" | bc -l` -eq 1 ] #bash cannot process float points so we have to use bc command that return 1 for true and 0 for false.
then
	echo "Warning!! The cpu is under heavy load"
else
	echo "Cpu under normal conditions"
fi






 

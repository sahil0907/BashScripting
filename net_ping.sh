#Author: Sahil Sharma
#About: A basic server status checker script from a ip text file
#Will improve with valid ip checker and custom range defining

#!/bin/bash

filepath="/home/sahil/BashScripting/ips.txt" #Your file path

while read -r ip #loop through the file
do
if [[ -z "$ip" ]] 
then
	continue
else
	ping -c 1 "$ip" &> /dev/null
	if [[ $? -eq 0  ]]
	then
		echo "$ip is up and running"
	else
		echo "$ip is down !!"
	fi
fi 
done < "$filepath"


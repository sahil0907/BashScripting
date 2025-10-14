#!/bin/bash
read -p "Enter your age" age

if [[ age -gt 20 ]]
then 
	echo "You are only greater than 20"

elif [[ age == 20   ]]
then 
	echo "you are 20 years old"

elif [[ age -le 20 ]]
then
	echo "you are less than 20"

else 

	echo "you are $age years old"

fi
	











#!/bin/bash

read -p "what is your age " age
read -p "what is your coutry " country

if [[ $age -gt 15 ]] && [[ $country == "India" ]]

then
	echo "YES"

else

	echo "NO"

fi







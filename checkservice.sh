#Author: Sahil Sharma
#About: A script to check if a service is up, if not then install & start it
#Run as a rootuser for a debian based system only
#!/bin/bash

start_service ()
{
echo "Starting service"
systemctl start "$service" 
systemctl enable "$service" 
systemctl status "$service" &>/dev/null

if [[ $? -ne 0 ]]
then
	echo "Service not installed properly"
	echo "Please check manually"
else
	echo "Service up  and running"
fi
}
read -p "Enter service name to check " service
echo "Checking if $service is present" &>/dev/null
systemctl status "$service" &>/dev/null


if [[ $? -ne 0 ]]
then
	echo "$service doesnt exists !!" 2>/dev/null
	echo "Installing it"
	apt  update
	apt install $service -y
	start_service
else
	start_service
fi


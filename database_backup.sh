#Author: Sahil Sharma
#About: To create a backup of your database in a compressed format here we used mysql we can use any other database also just the commands will change a bit,   Later we will add a seperate server on which backup will be saved


#!/bin/bash

[ $# -ne 3 ] && echo "Please enter valid parameters with script Example:" && echo "$0  _databasename_ _username_ _password_" && exit 1

db_name="$1" #the name of table or database
user="$2"
password="$3"
backupfile="$db_name-$(date +'%Y-%m-%d').sql.gz"
mysqldump -u "$user" -p "$password" "$db_name" | gzip > "$backupfile"

if [ $? -eq 0 ] 
then
	echo "Successful backup"
else
	echo "Error during backup"
fi 

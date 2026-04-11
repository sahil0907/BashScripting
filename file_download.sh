#!/bin/bash
if [[ -z $1 || -z $2 ]]
then
	echo "-------------------------------------------------"
	echo "Please Enter Directory to save and URL file path"
	echo "-------------------------------------------------"
	echo "Example: $0 Directory_path URL.txt"
	echo "-------------------------------------------------"
	exit 1
fi

DIR="$1"
FILE="$2"

while read -r url
do
if [[ -n "$url"  ]]
then
	echo "Downloading $url ... "
	wget -q -P "$DIR" "$url" && echo "Downloaded $url" || echo "Failed $url"	
fi
done < "$FILE"

echo "DONE"



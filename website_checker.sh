#Author: Sahil Sharma
#About: Script used to check if a website is up or not
#example: website_checker google.com


#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 URL"
    exit 1
fi

URL="$1"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "The website $URL is online (HTTP 200)."
else
    echo "Error: The website $URL returned HTTP $HTTP_CODE."
fi

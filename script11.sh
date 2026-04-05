#!/bin/bash
a=`df -h | awk '{print $5}' | cut -d "%" -f1 | sed -n '4p'`
if [ $a -gt 50 ]
then 
  echo " WARNING more than 50% storage is goneee"
else
  echo " Usage under 50%"
fi










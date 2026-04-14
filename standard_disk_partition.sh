#Author: Sahil Sharma
#About: A script to add new partitioning to a newly added disk. The name of the disk should be sdb or it can be changed

#!/bin/bash

is_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

echo "-----------------------------------------------------"
while true
do
total_size=`lsblk | grep -w "sdb" | awk '{print $4}'`
echo "Total size: ${total_size}B"
freespace=`parted /dev/sdb unit GB print free | grep "Free Space" | tail -n 1 | awk '{print $3}' | awk -F'.' '{print $1}'`
echo "Free Space: ${freespace}GB"
read  -p "Size of partition to add in GB " size

if [ -z "$freespace" ]
then
        echo "ERROR: No free space found on /dev/sdb or disk doesn't exist."
        exit 1
fi

if [[ "$size" -eq "q" ]]
then
        echo "Quitting !!"
        exit 0
fi

if ! is_integer "$size"
then
        echo "Enter a valid whole number"
        sleep 2
        continue
fi

if [[ "$size" -gt "$freespace" ]]
then
        echo "Out of Space"
        echo "You are asking for ${size}GB but available is ${freespace}"
        sleep 2
        continue
fi

fdisk /dev/sdb << EOF
n


+${size}G
w
q
EOF
if [[ $? -eq 0 ]]
then
        echo "Successfully created a partition"
        partprobe
        lsblk /dev/sdb
        break
else
        echo "Error while creating partition"
fi
done

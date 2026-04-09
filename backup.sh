#Author: Sahil Sharma
#About: A script to backup a folder and compress it with a date timestamp in backupname. Learn about how tar works without -C option.



#!/bin/bash

read -p "Enter directory path for backup: " DIR

# Check if the directory exists before proceeding
if [ ! -d "$DIR" ]; then
    echo "Error: $DIR is not a valid directory."
    exit 1
fi

# Configuration
PARENT_DIR=$(dirname "$DIR")
TARGET_NAME=$(basename "$DIR")
DATE=$(date '+%Y-%m-%d')
BACKUP_PATH="/backup/${TARGET_NAME}-${DATE}.tar.gz"

echo "Starting backup of: $TARGET_NAME"
echo "Target location: $BACKUP_PATH"

# -C: Changes to the parent directory
sudo tar -cvzf "$BACKUP_PATH" -C "$PARENT_DIR" "$TARGET_NAME"

echo "------------------------------------------"
echo "Backup Complete: $BACKUP_PATH"

#Author: Sahil Sharma
#This sript was made on debian system but can be modified for other distributions.

# 1. Permission Check

#[[ $EUID -ne 0 ]] && echo "Please run as root" && exit 1

INPUT_FILE="/home/sahil/BashScripting/username.txt" #Put your username file path here

LOG_FILE="/var/log/user_mgmt.log" #Put your log file path here



# 2. File Check if it exists or not

if [[ ! -f "$INPUT_FILE" ]]; then

    echo "Error: $INPUT_FILE not found."

    exit 1

fi



# 3. Start Logging

exec > >(tee -a "$LOG_FILE") 2>&1



while read -r username; do #better for handling spaces than for loop, reads one line at at time

    # Skip empty lines or comments

    [[ -z "$username" || "$username" =~ ^# ]] && continue
    
    if id "$username" &>/dev/null; then #checks if user exists or not

        echo "[EXISTS] User: $username"

        read -p "Delete user $username? (y/N): " choice < /dev/tty #we are redirecting output also to log file and taking input from inputfile the read will now read from the file instead of the input from screen so we have to manually add < /dev/tty to make sure it takes input from terminal and not from the file

        if [[ "$choice" == [Yy]* ]]; then

            # Check if user has active processes

            pkill -u "$username"

            userdel -rf "$username"

            echo "[DELETED] $username"

        fi

    else

        echo "[ADDING] $username"

        # 4. Add user with bash shell and create home dir

        useradd -m -s /bin/bash "$username"

        

        # 5. Set Password (using a default or prompt)

        echo "$username:default123" | chpasswd

        

        # 6. Force password change on first login

        chage -d 0 "$username"

        

        echo "[SUCCESS] $username added and forced to change password."

    fi

done < "$INPUT_FILE"



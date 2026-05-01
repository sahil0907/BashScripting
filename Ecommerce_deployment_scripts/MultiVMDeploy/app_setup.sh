#!/bin/bash
readonly DB_NAME="ecom_db"
readonly DB_USER="ecom_user"
readonly DB_PASS="ecom_password"
readonly DB_IP="192.168.15.136"
readonly APP_USER="ecom-service"
readonly PROJECT_DIR="/home/$APP_USER/ecommerce_app"
readonly GIT_URL="https://github.com/sahil0907/Ecommerce-app"
readonly SECRET_DIR="/home/$APP_USER/secrets.env"

set -euo pipefail
trap 'echo " Error in function ${FUNCNAME:-main} on line $LINENO"; exit 1' ERR

# setting dependencies
setup_dependencies()
{
    echo "Adding python3-venv"
    apt update -qq && apt install python3-venv git postgresql nginx curl sshpass  -y

    echo "Creating service user"
    if  ! id "$APP_USER" &>/dev/null 
    then
        useradd -m -s /usr/sbin/nologin "$APP_USER"
    fi
 
}


get_code()
{
    if [ -d "$PROJECT_DIR" ]
    then
        echo "Clearing the directory" #removing any old codebase 
        rm -rf "$PROJECT_DIR"
    fi    

    sudo -u "$APP_USER" -H git clone "$GIT_URL" "$PROJECT_DIR"
}
#setup ssh communication btw app. vm and nginx vm
setup_sshkeys()
{    echo "------------------------------------------------------"

    echo "SSH SETUP"
    local USER="nginx_user"
    local IP="192.168.15.136"
    local PASS="4323"
    #creating keys if not present
    if [ ! -f "/home/$APP_USER/.ssh/id_rsa" ]; then
        sudo -u "$APP_USER" mkdir -p "/home/$APP_USER/.ssh"
        sudo -u "$APP_USER" chmod 700 "/home/$APP_USER/.ssh"
        sudo -u "$APP_USER" ssh-keygen -t rsa -b 4096 -f "/home/$APP_USER/.ssh/id_rsa" -N ""
    fi

    sudo -u "$APP_USER" sshpass -p "$PASS" ssh-copy-id -o StrictHostKeyChecking=no "$USER@$IP"
    echo "------------------------------------------------------"

}

nginx_setup()

{      
     echo "------------------------------------------------------"

    echo "NGINX SETUP"
    echo " Syncing static assets to Nginx VM..."
    local USER="nginx_user"
    local IP="192.168.15.136"

    sudo -u "$APP_USER" rsync -avz "$PROJECT_DIR/app/static/" "$USER@$IP":/var/www/static/
    echo "------------------------------------------------------"
}


python_dependencies()
{    echo "------------------------------------------------------"

    echo "checking dependencesi"
    sudo -u "$APP_USER" -H  python3 -m venv "$PROJECT_DIR/venv"
    sudo -u "$APP_USER" -H "$PROJECT_DIR/venv/bin/pip" install --upgrade pip
    sudo -u "$APP_USER" -H "$PROJECT_DIR/venv/bin/pip" install --upgrade flask flask-sqlalchemy python-dotenv psycopg2-binary gunicorn
    #manual schema trigger
    sudo -u "$APP_USER" -H bash -c "export \$(cat $SECRET_DIR | xargs) && cd $PROJECT_DIR/app && ../venv/bin/python3 -c 'from app import app, init_db; init_db()'"
    echo "------------------------------------------------------"
}

provision_secrets()
{    echo "------------------------------------------------------"

    echo "Secret provisioning"
    local secretkey=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

    cat <<EOF > "$SECRET_DIR"
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_IP/$DB_NAME
SECRET_KEY=$secretkey
EOF 
    chmod 600 "$SECRET_DIR"
    chown "$APP_USER":"$APP_USER" "$SECRET_DIR"
    echo "------------------------------------------------------"
}

creating_service()
{
    echo "------------------------------------------------------"
    echo "Creating service user"
cat <<EOF > /etc/systemd/system/ecommerce.service
[Unit]
Description=Gunicorn Ecommerce Service

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$PROJECT_DIR/app
EnvironmentFile=$SECRET_DIR
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
echo "-------------------------------------"
echo "restarting the service"
        systemctl daemon-reload
        systemctl enable ecommerce
        systemctl restart ecommerce
}

main()
{
    setup_dependencies
    get_code
    provision_secrets
    setup_sshkeys
    nginx_setup
    python_dependencies
    creating_service


}

main
 



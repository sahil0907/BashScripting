#Author: Sahil Sharma 
#About: We are going to deploy the TIER-1 of the flask app with a script with all dependencies and using systemd service. We are using a service user without any password set to ensure security.


#!/bin/bash

# --- 1. CONFIGURATION ---
APP_USER="ecom-service"
APP_DIR="/home/$APP_USER/ecommerce-app"
REPO_URL="" 

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo " Please run this script with sudo."
   exit 1
fi

echo " Starting Production-Level Deployment..."

# --- 2. SYSTEM DEPENDENCIES (Idempotent) ---
apt update -qq >/dev/null 2>&1
PACKAGES=(python3 python3-pip python3-venv git curl lsof)
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then	#using dpkg for checking 
        echo "Installing $pkg..."
        apt install -y "$pkg"
    fi
done

# --- 3. SECURITY: SERVICE USER --- 
if ! id "$APP_USER" &>/dev/null; then
    # Create user with no login shell for security
    useradd -m -s /usr/sbin/nologin "$APP_USER"
    echo " Created service user: $APP_USER"
fi

# --- 4. SOURCE CODE GRAB FROM PUBLIC REPO  ---
echo " Fetching code from Git..."
if [ ! -d "$APP_DIR/.git" ]; then
    # First time: Clone the repo as the service user
    sudo -u "$APP_USER" -H git clone "$REPO_URL" "$APP_DIR"
else
    # Update: Fetch and Reset to mirror the remote main branch exactly using reset --hard
    sudo -u "$APP_USER" -H bash -c "cd $APP_DIR && git fetch --all && git reset --hard origin/main"
fi

# --- 5. ENVIRONMENT SETUP (Virtual Env) ---
if [ ! -d "$APP_DIR/venv" ]; then
    sudo -u "$APP_USER" -H python3 -m venv "$APP_DIR/venv"
fi

# Install/Update Python dependencies
sudo -u "$APP_USER" -H "$APP_DIR/venv/bin/pip" install --upgrade pip
sudo -u "$APP_USER" -H "$APP_DIR/venv/bin/pip" install flask flask-sqlalchemy python-dotenv

# Fix Ownership just in case ( even tho we ran commands as $APP_USER , double checking is good)
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chmod 750 "$APP_DIR"

# --- 6. PROCESS MANAGEMENT (Systemd Service): so that linux kernel can track this and it becomes more easy for us to manage with logs ---
echo "Configuring Systemd Service..."
cat <<EOF > /etc/systemd/system/ecommerce.service
[Unit]
Description=Flask Ecommerce Application
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
# Generate a secret key on the fly for security
Environment="FLASK_SECRET_KEY=$(python3 -c 'import os; print(os.urandom(24).hex())')"
ExecStart=$APP_DIR/venv/bin/python3 $APP_DIR/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable (start on boot), and restart the app
systemctl daemon-reload
systemctl enable ecommerce
systemctl restart ecommerce

# --- 7. AUTOMATED HEALTH CHECK ---
echo "Waiting for application to stabilize..."
sleep 5

# Check if the app is responding on localhost:5000
if curl -s --head http://127.0.0.1:5000/ | grep "200 OK" > /dev/null; then
    echo "DEPLOYMENT SUCCESSFUL: App is running under $APP_USER"
    echo "Status: $(systemctl is-active ecommerce)"
else
    echo "HEALTH CHECK FAILED!"
    echo "Check logs using: sudo journalctl -u ecommerce -n 50"
    exit 1
fi
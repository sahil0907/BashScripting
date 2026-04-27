#Author: Sahil Sharma
#About: We are going to deploy the TIER-2 of the flask app with a script with all dependencies and using systemd service. We are using a service user without any password set to ensure security. 

#!/bin/bash

# --- 1. CONFIGURATION ---
APP_USER="ecom-service"
APP_DIR="/home/$APP_USER/ecommerce-app"
REPO_URL="https://github.com/sahil0907/Ecommerce-app"
DB_NAME="ecom_db"
DB_USER="ecom_user"
DB_PASS="ecom_password"
# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo " Please run this script with sudo."
   exit 1
fi

echo " Starting Production-Level Deployment..."

# --- 2. SYSTEM DEPENDENCIES (Idempotent) ---
apt update -qq >/dev/null 2>&1
PACKAGES=(python3 python3-pip python3-venv git curl lsof postgresql postgresql-contrib libpq-dev) #here i need to install my psql
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then   #using dpkg for checking
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

#Setting up postgres
systemctl start postgresql
systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" || true
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" || true

# --- DEPLOYMENT LOGIC ---  
if [ ! -d "$APP_DIR/.git" ]; then
    echo "First time deploy: Cloning main branch"
    # We clone the main branch initially
    echo "Cloning into $APP_DIR..."
    sudo -u "$APP_USER" -H git clone --depth 1 "$REPO_URL" "$APP_DIR" || { echo "Git clone failed!"; exit 1; }
else
    echo "Updating existing code to latest from main"
    sudo -u "$APP_USER" -H bash -c "
        cd $APP_DIR
        git fetch origin main
        # Force the local branch to match the remote main branch exactly
        git reset --hard origin/main
        # Clean up any untracked files that aren't in git
        git clean -fd
    "
fi
# --- 5. ENVIRONMENT SETUP (Virtual Env) ---
if [ ! -d "$APP_DIR/venv" ]; then
    sudo -u "$APP_USER" -H python3 -m venv "$APP_DIR/venv"
fi

# Install/Update Python dependencies
sudo -u "$APP_USER" -H "$APP_DIR/venv/bin/pip" install --upgrade pip
sudo -u "$APP_USER" -H "$APP_DIR/venv/bin/pip" install flask flask-sqlalchemy python-dotenv
sudo -u "$APP_USER" -H "$APP_DIR/venv/bin/pip" install  psycopg2-binary

# Fix Ownership just in case ( even tho we ran commands as $APP_USER , double checking is good)
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chmod 750 "$APP_DIR"

# --- 6. PROCESS MANAGEMENT (Systemd Service): so that linux kernel can keep it up  
echo "Configuring Systemd Service..."
cat <<EOF > /etc/systemd/system/ecommerce.service
[Unit]
Description=Flask Ecommerce Application
After=network.target postgresql.service

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
# We use the variables defined at the top of the script
Environment="DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost/$DB_NAME" #we are providing passwords and usernames from here
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

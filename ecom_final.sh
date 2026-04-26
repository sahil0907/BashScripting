#!/bin/bash
set -euo pipefail

# --- CONFIG ---
readonly APP_USER="ecom-service"
readonly PROJECT_ROOT="/home/$APP_USER/ecommerce-app"
readonly REPO_URL="https://github.com/sahil0907/Ecommerce-app"
readonly DB_NAME="ecom_db"
readonly DB_USER="ecom_user"
readonly DB_PASS="ecom_password"
readonly LOG_FILE="/var/log/ecommerce_deploy.log"

# --- ERROR TRAP ---
trap 'echo "❌ Error on line $LINENO. Check $LOG_FILE for details."; exit 1' ERR

log_info() { echo "[$(date)] ℹ️  $1" | tee -a "$LOG_FILE"; }

# --- FUNCTIONS ---

setup_environment() {
    log_info "Setting up user and folder permissions..."
    if ! id "$APP_USER" &>/dev/null; then
        useradd -m -s /usr/sbin/nologin "$APP_USER"
    fi
    # The 'Gate Keeper' fix for Nginx
    chmod o+x "/home/$APP_USER"
    mkdir -p "$PROJECT_ROOT"
    chown "$APP_USER":"$APP_USER" "$PROJECT_ROOT"
}

provision_secrets() {
    log_info "Provisioning .env secrets..."
    local env_file="$PROJECT_ROOT/app/.env"
    # Create .env if it doesn't exist
    sudo -u "$APP_USER" bash -c "cat <<EOF > $env_file
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost/$DB_NAME
FLASK_SECRET_KEY=$(python3 -c 'import os; print(os.urandom(24).hex())')
EOF"
    chmod 600 "$env_file"
}

sync_db_schema() {
    log_info "Syncing PostgreSQL schema and seeding data..."
    # We call the init_db function directly via Python
    sudo -u "$APP_USER" "$PROJECT_ROOT/venv/bin/python3" -c "from app import app, init_db; init_db()"
}

configure_systemd() {
    log_info "Updating systemd service..."
    cat <<EOF > /etc/systemd/system/ecommerce.service
[Unit]
Description=Gunicorn Flask Service
After=network.target postgresql.service

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$PROJECT_ROOT/app
EnvironmentFile=$PROJECT_ROOT/app/.env
ExecStart=$PROJECT_ROOT/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl restart ecommerce
}

# --- MAIN FLOW ---
main() {
    setup_environment
    # ... (Include your git clone and venv setup here) ...
    provision_secrets
    sync_db_schema    # This solves your 'Internal Server Error'
    configure_systemd
    
    # Ensure Nginx can see the static files
    chmod -R 755 "$PROJECT_ROOT/app/static"
    
    log_info "🚀 Deployment Complete!"
}

main
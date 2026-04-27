#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
readonly APP_USER="ecom-service"
readonly PROJECT_ROOT="/home/$APP_USER/ecommerce-app"
readonly REPO_URL="https://github.com/sahil0907/Ecommerce-app"
readonly DB_NAME="ecom_db"
readonly DB_USER="ecom_user"
readonly DB_PASS="ecom_password"
readonly SAFE_ENV="/home/$APP_USER/app.env"
readonly LOG_FILE="/var/log/ecommerce_deploy.log"

# --- HELPER FUNCTIONS ---
log_info() { echo "[$(date)] ℹ️  $1" | tee -a "$LOG_FILE"; }

# Error handler  
trap 'echo "❌ Error in function ${FUNCNAME:-main} on line $LINENO"; exit 1' ERR

# --- CORE MODULES ---

setup_system_deps() {
    log_info "Installing system dependencies..."
    apt update -qq && apt install -y python3-venv postgresql nginx git curl
    
    if ! id "$APP_USER" &>/dev/null; then
        useradd -m -s /usr/sbin/nologin "$APP_USER"
    fi
    chmod o+x "/home/$APP_USER"
}

provision_secrets() {
    log_info "Creating secret environment file at $SAFE_ENV..."
    local secret_key=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
    
    cat <<EOF > "$SAFE_ENV"
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost/$DB_NAME
FLASK_SECRET_KEY=$secret_key
EOF
    chown "$APP_USER":"$APP_USER" "$SAFE_ENV"
    chmod 600 "$SAFE_ENV"
}

sync_source_code() {
    log_info "Syncing code from GitHub..."
    if [ -d "$PROJECT_ROOT" ]; then
        rm -rf "$PROJECT_ROOT"
    fi
    sudo -u "$APP_USER" -H git clone --depth 1 "$REPO_URL" "$PROJECT_ROOT"
}

init_database() {
    log_info "Initializing PostgreSQL..."
    systemctl start postgresql
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" || true
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true
    sudo -u postgres psql -d "$DB_NAME" -c "ALTER SCHEMA public OWNER TO $DB_USER;" || true
}

prepare_python_app() {
    log_info "Setting up VirtualEnv and Database Schema..."
    sudo -u "$APP_USER" -H python3 -m venv "$PROJECT_ROOT/venv"
    sudo -u "$APP_USER" -H "$PROJECT_ROOT/venv/bin/pip" install --upgrade pip
    sudo -u "$APP_USER" -H "$PROJECT_ROOT/venv/bin/pip" install flask flask-sqlalchemy python-dotenv psycopg2-binary gunicorn

    # The manual schema trigger
    sudo -u "$APP_USER" -H bash -c "export \$(cat $SAFE_ENV | xargs) && cd $PROJECT_ROOT/app && ../venv/bin/python3 -c 'from app import app, init_db; init_db()'"
}

configure_services() {
    log_info "Configuring Systemd and Nginx..."
    
    # Systemd Service
    cat <<EOF > /etc/systemd/system/ecommerce.service
[Unit]
Description=Gunicorn Ecommerce Service
After=network.target postgresql.service

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$PROJECT_ROOT/app
EnvironmentFile=$SAFE_ENV
ExecStart=$PROJECT_ROOT/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ecommerce
    systemctl restart ecommerce
    
    # Permissions for Nginx to serve static files
    chmod -R 755 "$PROJECT_ROOT/app/static"
    systemctl reload nginx
}

# --- MAIN EXECUTION ---
main() {
    [[ $EUID -ne 0 ]] && { echo "Must run as root"; exit 1; }
    
    setup_system_deps
    provision_secrets   
    sync_source_code     
    init_database
    prepare_python_app
    configure_services
    
    log_info "🚀 MODULAR DEPLOYMENT SUCCESSFUL!"
}

main
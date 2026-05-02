#!/bin/bash
apt update -qq && apt install postgresql -y &>/dev/null

readonly DB_NAME="ecom_db"
readonly DB_USER="ecom_user"
readonly DB_PASS="ecom_password"
readonly APP_IP="192.168.15.135"
# readonly POSTGRES_PATH="/etc/postgresql/$(ls /etc/postgresql)/main" #not dynamic and could give error if there are multiple versions installed
readonly POSTGRES_PATH=$(find /etc/postgresql -name "main" -type d  | head -n 1) #better for finding the path
#installing the postgres
#allowing firewall/opening ports to app vm only
ufw  --force enable 
ufw allow from 192.168.15.135 to any port 5432
ufw allow 22/tcp
#setting up the postgres configs
sed -i -r "s/^(#?)listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRES_PATH/postgresql.conf" 
echo "host $DB_NAME $DB_USER $APP_IP/32 md5" >> "$POSTGRES_PATH/pg_hba.conf"

init_database() {
    systemctl restart postgresql
    sudo -u postgres psql -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$DB_USER') THEN CREATE USER $DB_USER WITH PASSWORD '$DB_PASS'; END IF; END \$\$;"
    sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    # Grant permissions
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;"
 }
init_database
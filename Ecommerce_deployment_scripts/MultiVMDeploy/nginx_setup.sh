#!/bin/bash

# --- Tier 3: Nginx Infrastructure Script ---
if ! nginx -v 2>&1 /dev/null
then    
    apt update && apt install nginx -y
fi
# 1. Define where the actual code is currently located
CONF_NAME="ecommerce"

echo "Setting up Nginx for project at: $PROJECT_ROOT"

# 2. Create the configuration file dynamically
cat <<EOF > /etc/nginx/sites-available/ecommerce
server {
    listen 80;
    server_name ecom.com;

    location / {
        proxy_pass http://192.168.15.135:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /static/ {
        # Using the variable to ensure Nginx finds your assets
        alias /home/ecom-service/ecommerce-app/app/static/; #using rsync to get the static files from the application code
    }
}
EOF

# 3. Move to Nginx directories with sudo
echo "Applying system configurations..."
sudo ln -sf /etc/nginx/sites-available/$CONF_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 4. Final Safety Check & Reload
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "Nginx is now proxying to port 8000."
else
    echo "Error: Nginx configuration is invalid."
    exit 1
fi
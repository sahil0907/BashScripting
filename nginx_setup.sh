#!/bin/bash

# --- Tier 3: Nginx Infrastructure Script ---

# 1. Define where the actual code is currently located
PROJECT_ROOT="" 
CONF_NAME="ecommerce_app"

echo "Setting up Nginx for project at: $PROJECT_ROOT"

# 2. Create the configuration file dynamically
cat <<EOF > /tmp/$CONF_NAME
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /static/ {
        # Using the variable to ensure Nginx finds your assets
        alias $PROJECT_ROOT/static/;
    }
}
EOF

# 3. Move to Nginx directories with sudo
echo "Applying system configurations..."
sudo mv /tmp/$CONF_NAME /etc/nginx/sites-available/$CONF_NAME
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
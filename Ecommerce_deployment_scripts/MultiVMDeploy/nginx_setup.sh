#!/bin/bash
USER="nginx_user"
#creating a special user
useradd -m -s /bin/bash "$USER"
echo "4323" | passwd "$USER" --stdin
chown "$USER":"$USER" /var/www/static
chmod 755 "$USER":"$USER" /var/www/static

# --- Tier 3: Nginx Infrastructure Script ---
if ! nginx -v 2>&1 /dev/null
then    
    apt update -qq && apt install nginx -y
fi

CONF_NAME="ecommerce"

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
        alias /var/www/static; #using rsync to get the static files from the application code
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
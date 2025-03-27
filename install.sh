#!/bin/bash

# Colors for better display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Display logo
echo -e "${GREEN}"
echo "    ████████╗███████╗██╗     ██╗ ██████╗ ██████╗ ██╗  ██╗██╗"
echo "    ╚══██╔══╝██╔════╝██║     ██║██╔════╝██╔═══██╗██║ ██╔╝██║"
echo "       ██║   █████╗  ██║     ██║██║     ██║   ██║█████╔╝ ██║"
echo "       ██║   ██╔══╝  ██║     ██║██║     ██║   ██║██╔═██╗ ██║"
echo "       ██║   ███████╗███████╗██║╚██████╗╚██████╔╝██║  ██║██║"
echo "       ╚═╝   ╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝"
echo -e "${NC}"
echo "Telegram Ads Bot - Automatic Installation"
echo "----------------------------------------"

# Check root access
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run with root access${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Update system and install prerequisites
echo -e "${YELLOW}📦 Updating system and installing prerequisites...${NC}"
apt-get update
apt-get install -y software-properties-common

# Add PHP repository
echo -e "${YELLOW}📦 Adding PHP repository...${NC}"
add-apt-repository -y ppa:ondrej/php

# Update again after adding repository
apt-get update

# Install PHP and required extensions
echo -e "${YELLOW}📦 Installing PHP and extensions...${NC}"
apt-get install -y php7.4 php7.4-cli php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-fpm php7.4-json php7.4-openssl

# Verify PHP installation
if ! command -v php &> /dev/null; then
    echo -e "${RED}❌ PHP installation failed${NC}"
    exit 1
fi

# Install other prerequisites
echo -e "${YELLOW}📦 Installing other prerequisites...${NC}"
apt-get install -y git curl nginx mysql-server unzip

# Install Composer
echo -e "${YELLOW}📦 Installing Composer...${NC}"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# Verify Composer installation
if ! command -v composer &> /dev/null; then
    echo -e "${RED}❌ Composer installation failed${NC}"
    exit 1
fi

# Get GitHub URL
echo -e "${YELLOW}🌐 Setting up GitHub repository...${NC}"
GITHUB_URL="https://github.com/mcseali/tl.git"

# Get domain
echo -e "${YELLOW}🌐 Enter domain name:${NC}"
read -p "Please enter your domain name (e.g., example.com): " DOMAIN

# Create installation directory
INSTALL_DIR="/var/www/telegram-ads-bot"
echo -e "${YELLOW}📁 Creating installation directory...${NC}"
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Clone project
echo -e "${YELLOW}📥 Downloading project files...${NC}"
git clone $GITHUB_URL .

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
composer install

# Set permissions
echo -e "${YELLOW}🔒 Setting permissions...${NC}"
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR
chmod -R 777 $INSTALL_DIR/storage

# Configure PHP-FPM
echo -e "${YELLOW}⚙️ Configuring PHP-FPM...${NC}"
cat > /etc/php/7.4/fpm/pool.d/telegram-ads-bot.conf << 'EOL'
[telegram-ads-bot]
user = www-data
group = www-data
listen = /run/php/php7.4-fpm-telegram-ads-bot.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
php_admin_value[error_log] = /var/log/php7.4-fpm-telegram-ads-bot.log
php_admin_flag[log_errors] = on
EOL

# Configure Nginx
echo -e "${YELLOW}⚙️ Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/telegram-ads-bot << EOL
server {
    listen 80;
    server_name ${DOMAIN};
    root ${INSTALL_DIR}/public;
    index index.php;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # SSL configuration
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS settings
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Compression settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # Cache settings
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm-telegram-ads-bot.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Prevent access to sensitive files
    location ~ /\. {
        deny all;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
    }
}
EOL

# Enable site
ln -s /etc/nginx/sites-available/telegram-ads-bot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Install and configure SSL
echo -e "${YELLOW}🔒 Installing and configuring SSL...${NC}"
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

# Configure firewall
echo -e "${YELLOW}🛡️ Configuring firewall...${NC}"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

# Restart services
echo -e "${YELLOW}🔄 Restarting services...${NC}"
systemctl restart nginx
systemctl restart php7.4-fpm
systemctl restart mysql

# Configure MySQL
echo -e "${YELLOW}⚙️ Configuring MySQL...${NC}"
mysql -e "CREATE DATABASE IF NOT EXISTS telegram_ads CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'telegram_ads'@'localhost' IDENTIFIED BY '$(openssl rand -base64 12)';"
mysql -e "GRANT ALL PRIVILEGES ON telegram_ads.* TO 'telegram_ads'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Run PHP installation script
echo -e "${YELLOW}🚀 Running installation script...${NC}"
php install.php

echo -e "${GREEN}"
echo "✨ Installation completed successfully!"
echo "----------------------------------------"
echo "🔗 Website URL: https://${DOMAIN}"
echo "📱 To start using the bot, send a message to the Telegram bot"
echo "----------------------------------------"
echo -e "${NC}" 
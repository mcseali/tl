#!/bin/bash

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# نمایش لوگو
echo -e "${GREEN}"
echo "    ████████╗███████╗██╗     ██╗ ██████╗ ██████╗ ██╗  ██╗██╗"
echo "    ╚══██╔══╝██╔════╝██║     ██║██╔════╝██╔═══██╗██║ ██╔╝██║"
echo "       ██║   █████╗  ██║     ██║██║     ██║   ██║█████╔╝ ██║"
echo "       ██║   ██╔══╝  ██║     ██║██║     ██║   ██║██╔═██╗ ██║"
echo "       ██║   ███████╗███████╗██║╚██████╗╚██████╔╝██║  ██║██║"
echo "       ╚═╝   ╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝"
echo -e "${NC}"
echo "ربات تبلیغچی تلگرام - نصب خودکار"
echo "----------------------------------------"

# بررسی دسترسی root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ لطفاً با دسترسی root اجرا کنید${NC}"
    exit 1
fi

# بررسی پیش‌نیازها
echo -e "${YELLOW}🔍 بررسی پیش‌نیازها...${NC}"

# نصب پیش‌نیازها
apt-get update
apt-get install -y git curl php php-cli php-mysql php-curl php-json php-openssl php-mbstring php-zip unzip nginx mysql-server php-fpm

# نصب Composer
if ! command -v composer &> /dev/null; then
    echo -e "${YELLOW}📦 نصب Composer...${NC}"
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
fi

# دریافت آدرس گیت‌هاب
echo -e "${YELLOW}🌐 دریافت آدرس گیت‌هاب پروژه:${NC}"
read -p "لطفاً آدرس گیت‌هاب پروژه را وارد کنید (مثال: https://github.com/username/telegram-ads-bot.git): " GITHUB_URL

# دریافت دامنه
echo -e "${YELLOW}🌐 دریافت دامنه:${NC}"
read -p "لطفاً دامنه سایت را وارد کنید (مثال: example.com): " DOMAIN

# ایجاد دایرکتوری نصب
INSTALL_DIR="/var/www/telegram-ads-bot"
echo -e "${YELLOW}📁 ایجاد دایرکتوری نصب...${NC}"
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# کلون کردن پروژه
echo -e "${YELLOW}📥 دریافت فایل‌های پروژه...${NC}"
git clone $GITHUB_URL .

# نصب وابستگی‌ها
echo -e "${YELLOW}📦 نصب وابستگی‌ها...${NC}"
composer install

# تنظیم دسترسی‌ها
echo -e "${YELLOW}🔒 تنظیم دسترسی‌ها...${NC}"
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR
chmod -R 777 $INSTALL_DIR/storage

# تنظیم PHP-FPM
echo -e "${YELLOW}⚙️ تنظیم PHP-FPM...${NC}"
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

# تنظیم Nginx
echo -e "${YELLOW}⚙️ تنظیم Nginx...${NC}"
cat > /etc/nginx/sites-available/telegram-ads-bot << EOL
server {
    listen 80;
    server_name ${DOMAIN};
    root ${INSTALL_DIR}/public;
    index index.php;

    # تنظیمات امنیتی
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # تنظیمات SSL
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # تنظیمات HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # تنظیمات فشرده‌سازی
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # تنظیمات کش
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

    # جلوگیری از دسترسی به فایل‌های حساس
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

# فعال‌سازی سایت
ln -s /etc/nginx/sites-available/telegram-ads-bot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# نصب و تنظیم SSL
echo -e "${YELLOW}🔒 نصب و تنظیم SSL...${NC}"
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

# تنظیم فایروال
echo -e "${YELLOW}🛡️ تنظیم فایروال...${NC}"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

# راه‌اندازی مجدد سرویس‌ها
echo -e "${YELLOW}🔄 راه‌اندازی مجدد سرویس‌ها...${NC}"
systemctl restart nginx
systemctl restart php7.4-fpm
systemctl restart mysql

# تنظیم MySQL
echo -e "${YELLOW}⚙️ تنظیم MySQL...${NC}"
mysql -e "CREATE DATABASE IF NOT EXISTS telegram_ads CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'telegram_ads'@'localhost' IDENTIFIED BY '$(openssl rand -base64 12)';"
mysql -e "GRANT ALL PRIVILEGES ON telegram_ads.* TO 'telegram_ads'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# اجرای اسکریپت نصب PHP
echo -e "${YELLOW}🚀 اجرای اسکریپت نصب...${NC}"
php install.php

echo -e "${GREEN}"
echo "✨ نصب با موفقیت انجام شد!"
echo "----------------------------------------"
echo "🔗 آدرس وب‌سایت: https://${DOMAIN}"
echo "📱 برای شروع کار، به ربات تلگرام پیام دهید"
echo "----------------------------------------"
echo -e "${NC}" 
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
echo "Telegram Ads Bot - Complete Installation Guide"
echo "----------------------------------------"

# Check root access
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run with root access${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Update system and install prerequisites
echo -e "${YELLOW}📦 Updating system and installing prerequisites...${NC}"
apt-get update
apt-get install -y software-properties-common git curl wget unzip

# Add PHP repository with error checking
echo -e "${YELLOW}📦 Adding PHP repository...${NC}"
if ! add-apt-repository -y ppa:ondrej/php; then
    echo -e "${RED}❌ Failed to add PHP repository${NC}"
    echo -e "${YELLOW}📦 Trying alternative method...${NC}"
    apt-get install -y lsb-release ca-certificates apt-transport-https
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
fi

# Update again after adding repository
apt-get update

# Install PHP and required extensions
echo -e "${YELLOW}📦 Installing PHP and extensions...${NC}"
apt-get install -y php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-fpm php8.1-json php8.1-intl php8.1-redis

# Install Nginx and MySQL
echo -e "${YELLOW}📦 Installing Nginx and MySQL...${NC}"
apt-get install -y nginx mysql-server

# Install Composer
echo -e "${YELLOW}📦 Installing Composer...${NC}"
if ! command_exists composer; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    php -r "unlink('composer-setup.php');"
fi

# Get required information
echo -e "${YELLOW}🌐 Getting required information...${NC}"
echo -e "${YELLOW}Please provide the following information:${NC}"
echo "----------------------------------------"

# Get domain
read -p "Enter your domain name (e.g., example.com): " DOMAIN

# Get Telegram Bot details
echo -e "\n${YELLOW}Telegram Bot Configuration:${NC}"
read -p "Enter your Telegram Bot Token (from @BotFather): " BOT_TOKEN
read -p "Enter your Admin Telegram ID (from @userinfobot): " ADMIN_ID

# Get Database details
echo -e "\n${YELLOW}Database Configuration:${NC}"
read -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
read -p "Enter database name (default: telegram_ads): " DB_NAME
DB_NAME=${DB_NAME:-telegram_ads}
read -p "Enter database username (default: telegram_ads): " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-telegram_ads}
read -p "Enter database password (press enter for auto-generated): " DB_PASSWORD
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(openssl rand -base64 12)
    echo -e "${GREEN}Generated database password: ${DB_PASSWORD}${NC}"
fi

# Create installation directory
INSTALL_DIR="/var/www/telegram-ads-bot"
echo -e "${YELLOW}📁 Creating installation directory...${NC}"
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Clone project
echo -e "${YELLOW}📥 Downloading project files...${NC}"
git clone https://github.com/mcseali/tl.git .

# Create composer.json if it doesn't exist
if [ ! -f "composer.json" ]; then
    echo -e "${YELLOW}📦 Creating composer.json...${NC}"
    cat > composer.json << 'EOL'
{
    "name": "mcseali/telegram-ads-bot",
    "description": "Telegram Ads Bot",
    "type": "project",
    "require": {
        "php": "^8.1",
        "laravel/framework": "^10.0",
        "guzzlehttp/guzzle": "^7.0",
        "predis/predis": "^2.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    },
    "minimum-stability": "stable"
}
EOL
fi

# Create required directories
echo -e "${YELLOW}📁 Creating required directories...${NC}"
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p bootstrap/cache
mkdir -p public/uploads

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
composer install --no-interaction

# Create .env file
echo -e "${YELLOW}⚙️ Creating environment configuration...${NC}"
cat > .env << EOL
APP_NAME="Telegram Ads Bot"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://${DOMAIN}

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

TELEGRAM_BOT_TOKEN=${BOT_TOKEN}
ADMIN_CHAT_ID=${ADMIN_ID}

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
CACHE_DRIVER=redis
EOL

# Set permissions
echo -e "${YELLOW}🔒 Setting permissions...${NC}"
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR
chmod -R 777 $INSTALL_DIR/storage
chmod -R 777 $INSTALL_DIR/bootstrap/cache
chmod -R 777 $INSTALL_DIR/public/uploads

# Configure PHP-FPM
echo -e "${YELLOW}⚙️ Configuring PHP-FPM...${NC}"
mkdir -p /etc/php/8.1/fpm/pool.d/
cat > /etc/php/8.1/fpm/pool.d/telegram-ads-bot.conf << 'EOL'
[telegram-ads-bot]
user = www-data
group = www-data
listen = /run/php/php8.1-fpm-telegram-ads-bot.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
php_admin_value[error_log] = /var/log/php8.1-fpm-telegram-ads-bot.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300
EOL

# Configure Nginx
echo -e "${YELLOW}⚙️ Configuring Nginx...${NC}"
rm -f /etc/nginx/sites-enabled/telegram-ads-bot
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

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm-telegram-ads-bot.sock;
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
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN} --redirect

# Configure firewall
echo -e "${YELLOW}🛡️ Configuring firewall...${NC}"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

# Configure MySQL
echo -e "${YELLOW}⚙️ Configuring MySQL...${NC}"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USERNAME}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Run database migrations
echo -e "${YELLOW}🔄 Running database migrations...${NC}"
php artisan migrate --force

# Generate application key
echo -e "${YELLOW}🔑 Generating application key...${NC}"
php artisan key:generate

# Set up queue worker
echo -e "${YELLOW}⚙️ Setting up queue worker...${NC}"
cat > /etc/systemd/system/telegram-ads-worker.service << EOL
[Unit]
Description=Telegram Ads Bot Queue Worker
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start queue worker
systemctl enable telegram-ads-worker
systemctl start telegram-ads-worker

# Set up supervisor for queue worker
echo -e "${YELLOW}⚙️ Setting up supervisor...${NC}"
apt-get install -y supervisor
cat > /etc/supervisor/conf.d/telegram-ads-worker.conf << EOL
[program:telegram-ads-worker]
process_name=%(program_name)s_%(process_num)02d
command=php ${INSTALL_DIR}/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=${INSTALL_DIR}/storage/logs/worker.log
stopwaitsecs=3600
EOL

# Restart services
echo -e "${YELLOW}🔄 Restarting services...${NC}"
systemctl restart nginx
systemctl restart php8.1-fpm
systemctl restart mysql
systemctl restart supervisor

# Set up cron jobs
echo -e "${YELLOW}⚙️ Setting up cron jobs...${NC}"
(crontab -l 2>/dev/null | grep -v "artisan schedule:run") | crontab -
(crontab -l 2>/dev/null; echo "* * * * * cd ${INSTALL_DIR} && php artisan schedule:run >> /dev/null 2>&1") | crontab -

# Final setup
echo -e "${YELLOW}🚀 Running final setup...${NC}"
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link

echo -e "${GREEN}"
echo "✨ Installation completed successfully!"
echo "----------------------------------------"
echo "🔗 Website URL: https://${DOMAIN}"
echo "📱 To start using the bot, send a message to the Telegram bot"
echo "----------------------------------------"
echo -e "${NC}" 
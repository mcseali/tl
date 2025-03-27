FROM php:8.0-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy existing application directory
COPY . .

# Install dependencies
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/backups \
    && chmod -R 755 /var/www/html/logs

# Create backup directories
RUN mkdir -p /var/www/html/backups/{database,files,full} \
    && chown -R www-data:www-data /var/www/html/backups

# Create log directory
RUN mkdir -p /var/www/html/logs \
    && chown -R www-data:www-data /var/www/html/logs

# Start PHP-FPM
CMD ["php-fpm"] 
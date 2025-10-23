# Use PHP 8.2 with Apache (Debian Bookworm base)
FROM php:8.2-apache

# Avoid interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install required system dependencies and SQLite dev headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl sqlite3 \
    libsqlite3-dev libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable required Apache modules
RUN a2enmod rewrite headers env

# Set Apache DocumentRoot to BookStack's /public folder and allow .htaccess
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && echo '<Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>' > /etc/apache2/conf-available/public-dir.conf \
    && a2enconf public-dir

# Set working directory
WORKDIR /var/www/html

# Copy project files into the container
COPY . /var/www/html

# Install Composer (from official Composer image)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Fix Laravel/BookStack folder permissions and session directory
RUN mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage bootstrap/cache database \
    && chmod -R 775 storage bootstrap/cache database storage/framework/sessions

# ✅ Ensure HTTPS detection behind Render’s proxy
RUN echo 'SetEnvIf X-Forwarded-Proto https HTTPS=on' >> /etc/apache2/conf-available/render-https.conf \
    && echo 'RequestHeader set X-Forwarded-Proto "https"' >> /etc/apache2/conf-available/render-https.conf \
    && a2enconf render-https

# ✅ Force Laravel to re-read environment vars & APP_KEY on start
# This step is critical for fixing session decryption issues
CMD php artisan config:clear \
    && php artisan cache:clear \
    && php artisan view:clear \
    && php artisan route:clear \
    && php artisan config:cache \
    && apache2-foreground

# ----------------------------
# Stage 1: Base PHP + Apache
# ----------------------------
FROM php:8.2-apache

# Install required system packages and PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev unzip git curl sqlite3 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_sqlite pdo_mysql xml intl mbstring tokenizer xmlwriter \
    && a2enmod rewrite headers env \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html

# Fix permissions (for Laravel / BookStack)
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# ----------------------------
# Step 2: Laravel setup
# ----------------------------

# Ensure storage and bootstrap/cache are writable
RUN mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Clear caches to make sure ENV vars are used
RUN php artisan config:clear && \
    php artisan cache:clear && \
    php artisan view:clear

# ----------------------------
# Apache configuration
# ----------------------------
RUN echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
</Directory>" > /etc/apache2/conf-available/allowoverride.conf \
    && a2enconf allowoverride

# ----------------------------
# Expose and run
# ----------------------------
EXPOSE 80
CMD ["apache2-foreground"]

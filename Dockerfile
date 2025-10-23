FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev libonig-dev zip unzip git curl sqlite3 libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_sqlite pdo_mysql mbstring xml zip \
    && a2enmod rewrite headers env \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy all files
COPY . /var/www/html

# Fix permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Ensure Laravel folders exist and have proper permissions
RUN mkdir -p storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Clear caches (important for environment)
RUN php artisan config:clear || true && \
    php artisan cache:clear || true && \
    php artisan view:clear || true

# Enable Apache .htaccess overrides
RUN echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
</Directory>" > /etc/apache2/conf-available/allowoverride.conf \
    && a2enconf allowoverride

EXPOSE 80
CMD ["apache2-foreground"]

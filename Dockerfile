FROM php:8.2-apache

# Avoid interactive apt prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies & libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip curl sqlite3 pkg-config \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite zip mbstring \
    && a2enmod rewrite headers env \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html

# Set proper permissions for Laravel
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Ensure writable directories exist
RUN mkdir -p storage bootstrap/cache && chmod -R 775 storage bootstrap/cache

# Clear cached configurations (important for Render)
RUN php artisan config:clear || true && \
    php artisan cache:clear || true && \
    php artisan view:clear || true

# Allow .htaccess overrides for BookStack
RUN echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
</Directory>" > /etc/apache2/conf-available/allowoverride.conf \
    && a2enconf allowoverride

# Fix HTTPS redirect issues on Render
RUN echo 'SetEnvIf X-Forwarded-Proto https HTTPS=on' >> /etc/apache2/conf-available/render-https.conf && \
    a2enconf render-https

# Expose HTTP port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

# Use PHP 8.2 with Apache
FROM php:8.2-apache

# Avoid interactive install prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies & SQLite headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip zip libsqlite3-dev \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite
RUN a2enmod rewrite

# Fix HTTPS redirect issue behind Render proxy
RUN echo 'SetEnvIf X-Forwarded-Proto https HTTPS=on' >> /etc/apache2/conf-available/render-https.conf && \
    a2enconf render-https

# Set Apache DocumentRoot to BookStack's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Set working directory
WORKDIR /var/www/html

# Copy project files into container
COPY . /var/www/html

# Install Composer (from official Composer image)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install dependencies & clear Laravel caches
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && php artisan config:clear || true \
    && php artisan cache:clear || true \
    && php artisan route:clear || true \
    && php artisan view:clear || true

# Set proper permissions for Laravel & BookStack
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

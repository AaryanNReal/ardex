# Use PHP 8.2 with Apache (Debian Bookworm base)
FROM php:8.2-apache

# Avoid interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install required system dependencies and SQLite dev headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    zip \
    libsqlite3-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite (required by Laravel/BookStack)
RUN a2enmod rewrite

# Set Apache DocumentRoot to BookStack's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html

# Install Composer (copied from official Composer image)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies (no dev packages)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Fix Laravel/BookStack folder permissions
RUN chown -R www-data:www-data storage bootstrap/cache database \
    && chmod -R 775 storage bootstrap/cache database

# Expose HTTP port for Render
EXPOSE 80

# Start Apache server
CMD ["apache2-foreground"]

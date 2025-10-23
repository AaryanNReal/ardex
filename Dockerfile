# Use official PHP 8.2 with Apache
FROM php:8.2-apache

# Update system and install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    sqlite3 \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_sqlite zip \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite for Laravel/BookStack routing
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy the application code to the container
COPY . /var/www/html

# Install Composer (from official image)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Fix permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Expose port 80 (Render uses this automatically)
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

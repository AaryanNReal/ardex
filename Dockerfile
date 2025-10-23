# Base image
FROM php:8.2-apache

# Install required OS packages + build tools first
RUN apt-get update && apt-get install -y \
    apt-utils \
    git \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    sqlite3 \
    pkg-config \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite zip \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module (BookStack needs it)
RUN a2enmod rewrite

# Copy all app files
COPY . /var/www/html

# Set working directory
WORKDIR /var/www/html

# Install Composer from official image
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Fix file permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

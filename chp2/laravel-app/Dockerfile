# Stage 1: Build the Laravel application

# Use the official PHP image as the base image
FROM php:8.1-fpm AS builder

# Install system dependencies and PHP extensions required by Laravel
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip

# Install Composer (dependency manager for PHP)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory inside the container
WORKDIR /var/www

# Copy only the necessary files for Composer installation to leverage caching
COPY composer.json composer.lock ./

# Install PHP dependencies using Composer (without development dependencies)
RUN composer install --optimize-autoloader --no-dev

# Copy the rest of the Laravel application code into the container
COPY . .

# Set appropriate permissions for Laravel storage and bootstrap cache
RUN chown -R www-data:www-data storage bootstrap/cache

# Stage 2: Create a minimal production-ready image

# Use the official Nginx image as the base image
FROM nginx:alpine

# Copy the Laravel application from the builder stage
COPY --from=builder /var/www /var/www

# Copy the Nginx configuration file
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 (default for Nginx)
EXPOSE 80

# Set the working directory inside the container
WORKDIR /var/www

# Optionally, you can set environment variables if needed
ENV APP_ENV=production
ENV APP_KEY=your_application_key

# Start Nginx and PHP-FPM
CMD ["nginx", "-g", "daemon off;"]

#!/bin/bash

# WhatsApp AI Deployment Script for AlmaLinux Production with Apache

echo "Starting deployment for whatsparrot.in..."

# Pull latest changes
git pull origin main

# Install/update PHP dependencies
composer install --optimize-autoloader --no-dev

# Install/update Node.js dependencies
npm install

# Build assets
npm run build

# Run database migrations
php artisan migrate --force

# Clear and cache configurations
php artisan config:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Restart services
sudo systemctl restart whatsapp-queue
sudo systemctl restart php-fpm
sudo systemctl restart httpd
pm2 restart whatsapp-server

# Set proper permissions for AlmaLinux/Apache
sudo chown -R apache:apache /var/www/whatsapp-ai
sudo chmod -R 755 /var/www/whatsapp-ai
sudo chmod -R 775 /var/www/whatsapp-ai/storage
sudo chmod -R 775 /var/www/whatsapp-ai/bootstrap/cache

# Restore SELinux contexts
sudo restorecon -Rv /var/www/whatsapp-ai

echo "Deployment completed successfully for whatsparrot.in!"
#!/bin/bash

# WhatsApp AI Deployment Script for AlmaLinux Production with Nginx

echo "Starting deployment for whatsparrot.in..."

# Pull latest changes (if using git)
# git pull origin main

# Copy production environment
if [ -f ".env.production" ]; then
    cp .env.production .env
    echo "Production environment file copied"
fi

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

# Clear view cache to ensure fresh assets
php artisan view:clear

# Restart services
sudo systemctl restart whatsapp-queue 2>/dev/null || echo "whatsapp-queue service not found"
sudo systemctl restart php-fpm
sudo systemctl restart nginx
pm2 restart whatsapp-server

# Set proper permissions for AlmaLinux/Nginx
sudo chown -R nginx:nginx /var/www/whatsparrot.in
sudo chmod -R 755 /var/www/whatsparrot.in
sudo chmod -R 775 /var/www/whatsparrot.in/storage
sudo chmod -R 775 /var/www/whatsparrot.in/bootstrap/cache
sudo chmod -R 755 /var/www/whatsparrot.in/public/build*

# Restore SELinux contexts
sudo restorecon -Rv /var/www/whatsparrot.in

echo "Deployment completed successfully for whatsparrot.in!"
echo "Don't forget to update nginx configuration if needed!"
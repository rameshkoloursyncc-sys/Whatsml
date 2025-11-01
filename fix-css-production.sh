#!/bin/bash

# CSS Production Fix Script for WhatsApp AI
echo "🔧 Fixing CSS loading issues in production..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Clear all caches
print_status "Clearing Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Step 2: Ensure production environment
print_status "Setting up production environment..."
if [ -f ".env.production" ]; then
    cp .env.production .env
    print_status "Production environment copied"
fi

# Step 3: Rebuild assets completely
print_status "Rebuilding assets from scratch..."
rm -rf public/build*
npm run build

# Step 4: Cache configurations for production
print_status "Caching configurations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Step 5: Fix file permissions
print_status "Setting correct file permissions..."
sudo chown -R nginx:nginx /var/www/whatsparrot.in 2>/dev/null || print_warning "Could not set nginx ownership"
sudo chmod -R 755 /var/www/whatsparrot.in
sudo chmod -R 775 /var/www/whatsparrot.in/storage
sudo chmod -R 775 /var/www/whatsparrot.in/bootstrap/cache
sudo chmod -R 755 /var/www/whatsparrot.in/public/build*

# Step 6: Update nginx configuration
print_status "Updating nginx configuration..."
if [ -f "nginx-whatsapp-ai.conf" ]; then
    print_status "Copying nginx configuration..."
    sudo cp nginx-whatsapp-ai.conf /etc/nginx/sites-available/whatsapp-ai 2>/dev/null || \
    sudo cp nginx-whatsapp-ai.conf /etc/nginx/conf.d/whatsapp-ai.conf 2>/dev/null || \
    print_warning "Could not copy nginx config - please copy manually"
fi

# Step 7: Test nginx configuration
print_status "Testing nginx configuration..."
sudo nginx -t && print_status "Nginx config is valid" || print_error "Nginx config has errors"

# Step 8: Restart services
print_status "Restarting services..."
sudo systemctl restart php-fpm
sudo systemctl restart nginx
pm2 restart whatsapp-server 2>/dev/null || print_warning "Could not restart PM2 processes"

# Step 9: Verify build files
print_status "Verifying build files..."
if [ -f "public/build/manifest.json" ]; then
    print_status "✅ Main manifest found"
else
    print_error "❌ Main manifest missing"
fi

# Count CSS files
css_count=$(find public/build* -name "*.css" -type f 2>/dev/null | wc -l)
print_status "Found $css_count CSS files in build directories"

# Step 10: SELinux context (if applicable)
if command -v restorecon >/dev/null 2>&1; then
    print_status "Restoring SELinux contexts..."
    sudo restorecon -Rv /var/www/whatsparrot.in
fi

echo ""
print_status "🎉 CSS fix process completed!"
echo ""
print_warning "Next steps:"
print_warning "1. Test your website: https://whatsparrot.in"
print_warning "2. Check browser developer tools for any 404 errors on CSS files"
print_warning "3. If issues persist, check nginx error logs: sudo tail -f /var/log/nginx/error.log"
print_warning "4. Verify your .env file has correct APP_URL=https://whatsparrot.in"

echo ""
print_status "Common troubleshooting:"
echo "- If CSS still not loading, check browser network tab for failed requests"
echo "- Ensure your domain DNS is pointing to the correct server"
echo "- Check if SSL certificate is properly configured"
echo "- Verify nginx is serving static files from the correct document root"
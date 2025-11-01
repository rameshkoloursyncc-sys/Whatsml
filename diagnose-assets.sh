#!/bin/bash

# Asset Diagnostic Script for WhatsApp AI
echo "🔍 Diagnosing CSS/Asset Loading Issues..."

echo ""
echo "=== Environment Check ==="
echo "Current directory: $(pwd)"
echo "APP_ENV: $(grep APP_ENV .env 2>/dev/null || echo 'Not found')"
echo "APP_URL: $(grep APP_URL .env 2>/dev/null || echo 'Not found')"
echo "APP_DEBUG: $(grep APP_DEBUG .env 2>/dev/null || echo 'Not found')"

echo ""
echo "=== Build Files Check ==="
echo "Main build directory:"
ls -la public/build/ 2>/dev/null || echo "❌ public/build/ not found"

echo ""
echo "Module build directories:"
ls -la public/build-modules/ 2>/dev/null || echo "❌ public/build-modules/ not found"

echo ""
echo "=== Manifest Files ==="
echo "Main manifest:"
if [ -f "public/build/manifest.json" ]; then
    echo "✅ public/build/manifest.json exists"
    echo "Size: $(stat -c%s public/build/manifest.json 2>/dev/null || stat -f%z public/build/manifest.json 2>/dev/null) bytes"
else
    echo "❌ public/build/manifest.json missing"
fi

echo ""
echo "Module manifests:"
for dir in public/build-modules/*/; do
    if [ -d "$dir" ]; then
        module=$(basename "$dir")
        if [ -f "${dir}manifest.json" ]; then
            echo "✅ $module manifest exists"
        else
            echo "❌ $module manifest missing"
        fi
    fi
done

echo ""
echo "=== CSS Files Check ==="
echo "Looking for CSS files in build directories..."
find public/build* -name "*.css" -type f 2>/dev/null | head -10 || echo "No CSS files found"

echo ""
echo "=== Permissions Check ==="
echo "Public directory permissions:"
ls -la public/ | head -5

echo ""
echo "Build directory permissions:"
ls -la public/build*/ 2>/dev/null | head -10

echo ""
echo "=== Laravel Cache Status ==="
echo "Config cached: $([ -f bootstrap/cache/config.php ] && echo 'Yes' || echo 'No')"
echo "Routes cached: $([ -f bootstrap/cache/routes-v7.php ] && echo 'Yes' || echo 'No')"
echo "Views cached: $([ -d storage/framework/views ] && echo 'Yes' || echo 'No')"

echo ""
echo "=== Nginx Configuration Test ==="
if command -v nginx >/dev/null 2>&1; then
    echo "Testing nginx configuration..."
    sudo nginx -t 2>&1 || echo "❌ Nginx config test failed"
else
    echo "Nginx not found or not accessible"
fi

echo ""
echo "=== Quick Fix Suggestions ==="
echo "1. Clear Laravel caches: php artisan config:clear && php artisan view:clear"
echo "2. Rebuild assets: npm run build"
echo "3. Check nginx config: sudo nginx -t"
echo "4. Restart services: sudo systemctl restart nginx php-fpm"
echo "5. Check file permissions: sudo chown -R nginx:nginx /var/www/whatsparrot.in"

echo ""
echo "🔍 Diagnosis complete!"
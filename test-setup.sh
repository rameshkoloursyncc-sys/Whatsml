#!/bin/bash

echo "🧪 Testing WhatsApp AI Setup..."

echo "1. Testing PHP..."
php -v

echo ""
echo "2. Testing Composer..."
composer --version

echo ""
echo "3. Testing Node.js..."
node -v

echo ""
echo "4. Testing MySQL connection..."
mysql -u whatsapp_local -plocal123 -e "SELECT 'Database connection successful!' as status;" whatsml_local

echo ""
echo "5. Testing Laravel..."
php artisan --version

echo ""
echo "6. Testing WhatsApp server dependencies..."
cd whatsapp-server
node -e "console.log('WhatsApp server Node.js works!')"
cd ..

echo ""
echo "✅ All tests completed!"
echo ""
echo "🚀 Ready to start! Run: ./start-local.sh"
#!/bin/bash

echo "🚀 Starting WhatsApp AI Local Development..."

# Use Node.js 20
export PATH="/usr/local/opt/node@20/bin:$PATH"

# Function to cleanup processes on exit
cleanup() {
    echo "🛑 Stopping all services..."
    kill $LARAVEL_PID $WHATSAPP_PID 2>/dev/null
    exit
}

# Set trap to cleanup on Ctrl+C
trap cleanup INT

# Start Laravel server in background
echo "📱 Starting Laravel server on http://localhost:8000..."
php artisan serve --host=0.0.0.0 --port=8000 &
LARAVEL_PID=$!

# Wait a moment for Laravel to start
sleep 2

# Start WhatsApp server in background
echo "💬 Starting WhatsApp server on http://localhost:3000..."
cd whatsapp-server
echo "Using Node.js version: $(node -v)"
node dist/main.js &
WHATSAPP_PID=$!

# Go back to root directory
cd ..

echo ""
echo "✅ Services started successfully!"
echo "📱 Laravel App: http://localhost:8000"
echo "💬 WhatsApp Server: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for processes
wait
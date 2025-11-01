#!/bin/bash

# GitHub Sync Script for WhatsApp AI Production
echo "🔄 Syncing with GitHub repository..."

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

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "This is not a git repository. Initializing..."
    
    # Initialize git repository
    git init
    
    # Add GitHub remote (replace with your actual repository URL)
    read -p "Enter your GitHub repository URL (e.g., https://github.com/username/whatsapp-ai.git): " repo_url
    git remote add origin "$repo_url"
    
    print_status "Git repository initialized with remote: $repo_url"
fi

# Check current status
print_status "Checking current git status..."
git status

# Stash any local changes
print_status "Stashing local changes..."
git stash push -m "Local changes before sync - $(date)"

# Fetch latest changes from GitHub
print_status "Fetching latest changes from GitHub..."
git fetch origin

# Get current branch
current_branch=$(git branch --show-current)
print_status "Current branch: $current_branch"

# Pull latest changes
print_status "Pulling latest changes..."
if git pull origin "$current_branch"; then
    print_status "✅ Successfully pulled latest changes"
else
    print_error "❌ Failed to pull changes. You may need to resolve conflicts."
    
    # Show what files have conflicts
    print_warning "Files with conflicts:"
    git diff --name-only --diff-filter=U
    
    echo ""
    print_warning "To resolve conflicts:"
    print_warning "1. Edit the conflicted files manually"
    print_warning "2. Run: git add <file>"
    print_warning "3. Run: git commit -m 'Resolve merge conflicts'"
    print_warning "4. Run this script again"
    
    exit 1
fi

# Apply stashed changes if any
if git stash list | grep -q "stash@{0}"; then
    print_warning "You have stashed changes. Apply them with:"
    print_warning "git stash pop"
    
    read -p "Do you want to apply stashed changes now? (y/n): " apply_stash
    if [ "$apply_stash" = "y" ] || [ "$apply_stash" = "Y" ]; then
        git stash pop
        print_status "Stashed changes applied"
    fi
fi

# Copy production environment
if [ -f ".env.production" ]; then
    cp .env.production .env
    print_status "Production environment file copied"
fi

# Install/update dependencies
print_status "Installing PHP dependencies..."
composer install --optimize-autoloader --no-dev

print_status "Installing Node.js dependencies..."
npm install

# Build assets
print_status "Building production assets..."
npm run build

# Clear and cache Laravel configurations
print_status "Optimizing Laravel..."
php artisan config:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set proper permissions
print_status "Setting file permissions..."
sudo chown -R apache:apache /var/www/whatsparrot.in 2>/dev/null || print_warning "Could not set apache ownership"
sudo chmod -R 755 /var/www/whatsparrot.in
sudo chmod -R 775 /var/www/whatsparrot.in/storage
sudo chmod -R 775 /var/www/whatsparrot.in/bootstrap/cache
sudo chmod -R 755 /var/www/whatsparrot.in/public/build*

# Restart services
print_status "Restarting services..."
sudo systemctl restart php-fpm
sudo systemctl restart httpd
pm2 restart whatsapp-server 2>/dev/null || print_warning "Could not restart PM2"

# SELinux context
if command -v restorecon >/dev/null 2>&1; then
    print_status "Restoring SELinux contexts..."
    sudo restorecon -Rv /var/www/whatsparrot.in
fi

echo ""
print_status "🎉 GitHub sync completed successfully!"
echo ""
print_warning "What was done:"
print_warning "✅ Pulled latest code from GitHub"
print_warning "✅ Updated dependencies"
print_warning "✅ Built production assets"
print_warning "✅ Optimized Laravel configuration"
print_warning "✅ Set proper file permissions"
print_warning "✅ Restarted services"

echo ""
print_status "Next steps:"
print_status "1. Test your website: https://whatsparrot.in"
print_status "2. Check if CSS is loading properly"
print_status "3. Monitor logs for any errors"
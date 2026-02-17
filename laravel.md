# Project Setup Guide

This guide explains how to set up the project and create the initial Global Admin user.

## Prerequisites

- [PHP](https://www.php.net/) >= 8.1
- [Composer](https://getcomposer.org/)
- [Node.js](https://nodejs.org/) & NPM
- A database (MySQL, PostgreSQL, etc.)

## Windows Quick Setup

If you are on Windows, run the same manual commands below in PowerShell (no project-specific batch file is required):

```powershell
copy .env.example .env
composer install
npm install
npm run build
php artisan key:generate
php artisan migrate
php artisan db:seed --class=SuperAdminSeeder
php artisan storage:link
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## Manual Setup

If you prefer to set up manually or are on a different OS, follow these steps:

### 1. Configure Environment

Copy the example environment file and configure your database settings:

```bash
cp .env.example .env
```

Open `.env` and set your database credentials (`DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).

### 2. Install Dependencies

```bash
composer install
npm install
npm run build
```

### 3. Generate App Key

```bash
php artisan key:generate
```

### 4. Database Setup

Run the migrations to create the database tables:

```bash
php artisan migrate
```

### 5. Create Global Admin (Seeding)

To inject the global admin user, run the specific seeder:

```bash
php artisan db:seed --class=SuperAdminSeeder
```

Or run all seeders (which includes the SuperAdminSeeder):

```bash
php artisan db:seed
```

This will create a user with the following credentials (by default):

- **Email:** `superadmin@example.com`
- **Password:** `password`
- **Role:** `super_admin`

> **Note:** You can check or modify the default credentials in `database/seeders/SuperAdminSeeder.php`.

## Running the Application

Start the local development server:

```bash
php artisan serve
```

Access the application at `http://localhost:8000`.

## Server (Linux) Setup

For deploying to a Linux server (Ubuntu/Debian-based), follow the manual steps shown below. Ensure `.env` contains production database and mail settings before running commands.

If `.env` is missing, copy from the example and edit it to match your production credentials:

```bash
cp .env.example .env
# edit .env with DB and mail settings
```

When ready, run the commands highlighted in the EC2/Ubuntu section below to install dependencies, build assets, generate the app key, run migrations, and seed the Super Admin user.

Notes:
- Use `php artisan migrate --force` when running non-interactively — ensure your DB is ready.
- After deployment, set up a process manager (systemd or supervisor) to run queue workers and schedule cron jobs. Example Supervisor programs or systemd service files are environment-specific and should be created according to your server policies.

### Manual seeder command (if you prefer not to run the script)

To inject the global admin manually on the server, run:

```bash
php artisan db:seed --class=SuperAdminSeeder
```

Change the default Super Admin password immediately after first login by editing the user record or using tinker.

## Deployment Options

Below are step-by-step deployment instructions for two common hosting environments: shared hosting (cPanel/FTP) and an EC2 (Ubuntu) instance. These steps are written to be practical and adaptable — follow the path that matches your hosting provider's capabilities.

---

**Shared Hosting (cPanel / FTP)**

When deploying to a shared host (cPanel), you commonly have limited SSH access or none at all. Use these steps when you have either full SSH access or only FTP.

- Requirements:
	- PHP 8.1+ (match local dev PHP version)
	- MySQL or MariaDB database
	- If possible: SSH + Composer + Node.js on host (preferred)

- Steps (preferred: you have SSH access):
	1. Upload repository via `git clone` or SFTP to your document root (or a subfolder). If using Git, clone into a deploy directory and then copy files to `public_html`.
	2. Ensure `.env` is present. Copy `.env.example` to `.env` and update database and mail credentials.
	3. On the host, run:

```bash
composer install --no-dev --optimize-autoloader
npm ci && npm run build
php artisan key:generate --force
php artisan migrate --force
php artisan db:seed --class=SuperAdminSeeder
php artisan storage:link
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

	4. Set permissions for storage and cache (example):

```bash
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
```

	5. If SSH/Composer is NOT available on the host:
		 - Run `composer install` locally and upload the `vendor/` directory via SFTP.
		 - Run `npm ci && npm run build` locally and upload the `public/build` or `public/assets` output.
		 - Create and edit `.env` on the host (upload `.env` after editing locally).
		 - Apply database migrations: if you cannot run `php artisan migrate`, export your local DB schema (or specific migration SQL) and import via phpMyAdmin. Be careful to match table prefixes and engine options.

	6. Scheduled tasks & queues:
		 - If your host supports cron, add a cron entry to run the Laravel scheduler every minute:

```cron
* * * * * cd /home/username/path-to-project && php artisan schedule:run >> /dev/null 2>&1
```

		 - For queues, shared hosts usually do not support persistent workers; use a cron or service offered by the host to run `php artisan queue:work` periodically, or use a third-party worker service.

	7. SSL / domains:
		 - Use cPanel's Let's Encrypt or AutoSSL to install certificates.

	8. Notes:
		 - Always change the seeded Super Admin password after first login.
		 - If you cannot run migrations on the host, plan to run them locally and import the SQL.

---

**EC2 (Ubuntu) – Recommended for production**

This section covers a typical Ubuntu EC2 deployment using Nginx + PHP-FPM, Composer, Node, Supervisor (or systemd) for queue workers, and optional RDS for the database.

- Recommended instance: `t3.small` or `t3.medium` for small production; adjust CPU/RAM to traffic. For testing `t3.micro` may suffice.
- Storage: at least 20–40 GB (EBS). Use separate volumes for logs if needed.
- OS: Ubuntu 22.04 LTS (or similar).

- Required software:
	- Nginx
	- PHP-FPM 8.1+ with extensions: `pdo_mysql`, `mbstring`, `openssl`, `tokenizer`, `xml`, `curl`, `zip`, `gd`, `fileinfo`, `bcmath`
	- Composer
	- Node.js + npm (for building frontend)
	- MySQL (or use Amazon RDS)
	- Supervisor or systemd for process management
	- Certbot (for SSL)

- Basic provisioning steps (Ubuntu):

```bash
# update and install
sudo apt update && sudo apt upgrade -y

# install nginx
sudo apt install -y nginx

# install PHP and extensions (example)
sudo apt install -y php8.1-fpm php8.1-mysql php8.1-xml php8.1-mbstring php8.1-curl php8.1-zip php8.1-gd php8.1-bcmath php8.1-cli php8.1-intl

# install composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# install node (example with NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

- Deploy application (server-side):

```bash
# as the deploy user, in /var/www/your-app
git clone <your-repo> .
cp .env.example .env
# Edit .env with DB and app settings (or use AWS Secrets Manager / Parameter Store)
composer install --no-dev --prefer-dist --optimize-autoloader
npm ci
npm run build
php artisan key:generate --force
php artisan migrate --force
php artisan db:seed --class=SuperAdminSeeder
php artisan storage:link
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

- Permissions (adjust `www-data` if using different user):

```bash
sudo chown -R www-data:www-data /var/www/your-app/storage /var/www/your-app/bootstrap/cache
sudo chmod -R 775 /var/www/your-app/storage /var/www/your-app/bootstrap/cache
```

- Nginx site example (place in `/etc/nginx/sites-available/your-app`):

```nginx
server {
		listen 80;
		server_name yourdomain.com www.yourdomain.com;
		root /var/www/your-app/public;

		add_header X-Frame-Options "SAMEORIGIN";
		add_header X-Content-Type-Options "nosniff";

		index index.php;

		location / {
				try_files $uri $uri/ /index.php?$query_string;
		}

		location ~ \.php$ {
				include snippets/fastcgi-php.conf;
				fastcgi_pass unix:/run/php/php8.1-fpm.sock;
		}

		location ~ /\.ht {
				deny all;
		}
}
```

Enable the site and reload Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/your-app /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

- Scheduler & Queue workers:
	- Scheduler: add a cron entry for the deploy user or root:

```cron
* * * * * cd /var/www/your-app && php artisan schedule:run >> /dev/null 2>&1
```

	- Queue workers (production): use `supervisor` or a systemd service. Example `supervisor` config (`/etc/supervisor/conf.d/your-app-worker.conf`):

```ini
[program:your-app-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/your-app/artisan queue:work --sleep=3 --tries=3 --timeout=90
autostart=true
autorestart=true
numprocs=2
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/your-app/storage/logs/worker.log
```

After creating the file:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start your-app-worker:*
```

- SSL (Let's Encrypt):

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

- Security & best practices:
	- Use an RDS or managed DB for production when possible.
	- Use IAM / Secrets Manager for credentials where possible.
	- Configure UFW: allow SSH (22), HTTP (80), HTTPS (443). Close other ports.
	- Monitor logs and set up backups for DB and EBS volumes.

---

### Quick checklist before going live

- Ensure `.env` is set with production DB, cache, queue, and mail settings.
- Run migrations and seed Super Admin: `php artisan db:seed --class=SuperAdminSeeder`.
- Ensure `storage/` and `bootstrap/cache` are writable by the web server user.
- Configure SSL and DNS.
- Configure process manager for queue workers and cron for scheduler.
- Rotate or change the seeded Super Admin password after first login.

If you'd like, I can also add example `systemd` unit files or a Supervisor config in the repo. Let me know which you prefer.

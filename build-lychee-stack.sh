#!/bin/bash

# Build script for Lychee https://github.com/LycheeOrg/Lychee
#
## Installs Server requirements
## Install and compiles source from Master Branch
#
### Creates the lychee database
### Lychee configuration .env
### Apply directory and file permissions
#
# MAKE SURE TO REVIEW AND UPDATE VARIABLES: mysql password, APP_URL, Nginx server_name etc..
#
# THIS HAS BEEN TEST ON Ubuntu 22.04.4 LTS (Jammy Jellyfish)

# Remove php8.1
sudo apt remove -y php8.1-*

# Update and upgrade the system
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y nginx software-properties-common dirmngr ca-certificates apt-transport-https curl git unzip

# Add the MariaDB repository and install MariaDB 11
sudo curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
sudo apt update
sudo apt install -y mariadb-server mariadb-client

# Add the PHP repository for PHP 8.3
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP 8.3 and required extensions
sudo apt install -y php8.3 php8.3-fpm php8.3-common php8.3-bcmath php8.3-mbstring php8.3-gd php8.3-xml php8.3-sqlite3 php8.3-mysql php8.3-mysqli 

# Install FFmpeg and ImageMagick
sudo apt install -y ffmpeg imagemagick

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
sudo apt install -y nodejs

# Start and enable Nginx and MariaDB services
sudo systemctl start nginx
sudo systemctl enable nginx

sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure the MariaDB installation and set root password
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '[ENTER PASSWORD]'; FLUSH PRIVILEGES;"

# Create the lychee mysql database

# Define variables
MYSQL_ROOT_PASSWORD="[ENTER PASSWORD]"
DATABASE_NAME="lychee_db"

# MySQL commands to create database and user
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${DATABASE_NAME};
FLUSH PRIVILEGES;
EXIT;
EOF

# Restart PHP-FPM service
sudo systemctl restart php8.3-fpm

# Configure Nginx to use PHP processor

cat <<EOL | sudo tee /etc/nginx/sites-available/lychee
server {
    listen 80;
    server_name [ENTER HOSTNAME];

    ##### Path to the Lychee public/ directory.
    root /var/www/html/Lychee/public/;
    index index.php;

    # If the request is not for a valid file (image, js, css, etc.), send to bootstrap
    if (!-e \$request_filename)
    {
        rewrite ^/(.*)$ /index.php?/\$1 last;
        break;
    }

    # Serve /index.php through PHP
    location = /index.php {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;

        # Mitigate https://httpoxy.org/ vulnerabilities
        fastcgi_param HTTP_PROXY "";

        ######### Make sure this is the correct socket for your system
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        ######## You may need to replace \$document_root with the absolute path to your public folder.
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE "post_max_size=100M
            max_execution_time=200
            upload_max_filesize=30M
            memory_limit=300M";
        fastcgi_param PATH /usr/local/bin:/usr/bin:/bin;
        include fastcgi_params;
    }
    # Deny access to other .php files, rather than exposing their contents
    location ~ [^/]\.php(/|$) {
        return 403;
    }

    # [Optional] Lychee-specific logs
    error_log  /var/log/nginx/lychee.error.log;
    access_log /var/log/nginx/lychee.access.log;

    # [Optional] Remove trailing slashes from requests (prevents SEO duplicate content issues)
    rewrite ^/(.+)/$ /\$1 permanent;
}
EOL

# Enable the lychee site
sudo ln -s /etc/nginx/sites-available/lychee /etc/nginx/sites-enabled/lychee

# Test Nginx configuration and reload
sudo nginx -t
sudo systemctl reload nginx

# Clone the Lychee repository and set up the application
sudo git clone https://www.github.com/LycheeOrg/Lychee /var/www/html/Lychee
cd /var/www/html/Lychee
sudo composer install --no-dev
sudo npm install
sudo npm run build

# Adjust Lychee directory and file permissions
sudo chown -R root:www-data /var/www/html/Lychee
sudo find /var/www/html/Lychee -type f -exec chmod 664 {} \; 
sudo find /var/www/html/Lychee -type d -exec chmod 775 {} \;
sudo chmod -R ug+rwx /var/www/html/Lychee/storage /var/www/html/Lychee/bootstrap/cache
sudo chmod -R ug+rwx /var/www/html/Lychee/. /var/www/html/Lychee/database /var/www/html/Lychee/public

#php artisan lychee:fix-permissions --dry-run=0

# Apple Lychee configuration parameters
# Define the file path
FILE="/var/www/html/Lychee/.env"

# Use sed to find and replace the APP_URL line
sed -i 's|^APP_URL=http://localhost|APP_URL=http://pve.home.arpa|' "$FILE"
sed -i 's|^DB_CONNECTION=sqlite|DB_CONNECTION=mysql|' "$FILE"
sed -i 's|^DB_HOST=|DB_HOST=127.0.0.1|' "$FILE"
sed -i 's|^DB_PORT=|DB_PORT=3306|' "$FILE"
sed -i 's|^#DB_DATABASE=|DB_DATABASE=lychee_db|' "$FILE"
sed -i 's|^DB_USERNAME=|DB_USERNAME=root|' "$FILE"
sed -i 's|^DB_PASSWORD=|DB_PASSWORD=[ENTER PASSWORD]|' "$FILE"

echo "Installation complete. Nginx, MariaDB 11, PHP 8.3, Node.js, npm, and required extensions have been installed and Lychee is set up."
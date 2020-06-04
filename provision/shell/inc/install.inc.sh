#!/bin/bash
# 
# install.inc.sh
# 

function reboot_webserver_helper() {

    if [ $INSTALL_NGINX_INSTEAD != 1 ]; then
        sudo service apache2 restart
    fi

    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        sudo systemctl restart php7.2-fpm
        sudo systemctl restart nginx
    fi

    echo 'Rebooting your webserver'
}


function start_provisionning(){
    alert_info "Provisioning virtual machine..."
    alert_info "$(alert_line)"
    alert_info "You choose to install ${CMS} with the stack ${STACK}"
    alert_info "Your project directory will be ${PROJECT_DIR} and web root ${WEB_ROOT}"
    alert_info "It will work on php ${PHP_BASE_VERSION}"
}
start_provisionning


# /*=========================================
# =            CORE / BASE STUFF            =
# =========================================*/
function install_base(){
    sudo apt-get update

    # The following is "sudo apt-get -y upgrade" without any prompts
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

    sudo apt-get install -y build-essential
    sudo apt-get install -y tcl
    sudo apt-get install -y software-properties-common
    sudo apt-get install -y python-software-properties
    sudo apt-get -y install vim
    sudo apt-get -y install git

    sudo apt-get -y install shellcheck

    # Weird Vagrant issue fix
    sudo apt-get install -y ifupdown
}
install_base



# /*======================================
# =            INSTALL APACHE            =
# ======================================*/
function install_apache(){
    # Install the package
    sudo add-apt-repository -y ppa:ondrej/apache2 # Super Latest Version
    sudo apt-get update
    sudo apt-get -y install apache2

    # Remove "html" folder
    rm -rf /var/www/html
    rm -rf /var/www/public/html

    if [ "${USE_HTTPS}" ]; then
        sudo a2enmod ssl
        sudo service apache2 restart
    
        cp "${PATH_PROVISION_APACHE}${FILE_APACHE_SSL_CONF}" "${PATH_A2_SITES_AVAILABLE}"
    fi
    cp "${PATH_PROVISION_APACHE}${FILE_APACHE_CONF}" "${PATH_A2_SITES_AVAILABLE}"
    
    cd "${PATH_PROVISION_APACHE}" || exit
    sudo chmod 644 "${PATH_A2_SITES_AVAILABLE}${FILE_APACHE_CONF}"
    sudo a2ensite "${FILE_APACHE}"

    if [ "${USE_HTTPS}" ]; then
        # we reset initial file
        cd "${PATH_PROVISION_APACHE}" || exit
        
        sudo chmod 644 "${PATH_A2_SITES_AVAILABLE}${FILE_APACHE_SSL_CONF}"
        sudo a2ensite "${FILE_APACHE_SSL}"
    fi

    sudo service apache2 restart

    # Squash annoying FQDN warning
    echo "ServerName scotchbox" | sudo tee /etc/apache2/conf-available/servername.conf
    sudo a2enconf servername

    # Enabled missing h5bp modules (https://github.com/h5bp/server-configs-apache)
    sudo a2enmod expires
    sudo a2enmod headers
    sudo a2enmod include
    sudo a2enmod rewrite

    sudo service apache2 restart
}


if [ $INSTALL_NGINX_INSTEAD != 1 ]; then
    install_apache
fi



# /*=====================================
# =            INSTALL NGINX            =
# =====================================*/
function install_nginx(){
    # Install Nginx
    sudo add-apt-repository -y ppa:ondrej/nginx-mainline # Super Latest Version
    sudo apt-get update
    sudo apt-get -y install nginx
    sudo systemctl enable nginx

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Make sure your web server knows you did this...
    MY_WEB_CONFIG="server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    }"
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx
}
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    install_nginx
fi




# /*===================================
# =            INSTALL PHP            =
# ===================================*/
function install_php(){
    # Install PHP
    sudo add-apt-repository -y ppa:ondrej/php # Super Latest Version (currently 7.2)
    sudo apt-get update
    sudo apt-get install -y php7.2

    # Make PHP and Apache friends
    if [ $INSTALL_NGINX_INSTEAD != 1 ]; then

        sudo apt-get -y install libapache2-mod-php

        # Add index.php to readable file types
        MAKE_PHP_PRIORITY='<IfModule mod_dir.c>
            DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
        </IfModule>'
        echo "$MAKE_PHP_PRIORITY" | sudo tee /etc/apache2/mods-enabled/dir.conf

        sudo service apache2 restart

    fi

    # Make PHP and NGINX friends
    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

        # FPM STUFF
        sudo apt-get -y install php7.2-fpm
        sudo systemctl enable php7.2-fpm
        sudo systemctl start php7.2-fpm

        # Fix path FPM setting
        echo 'cgi.fix_pathinfo = 0' | sudo tee -a /etc/php/7.2/fpm/conf.d/user.ini
        sudo systemctl restart php7.2-fpm

        # Add index.php to readable file types and enable PHP FPM since PHP alone won't work
        MY_WEB_CONFIG="server {
            listen 80 default_server;
            listen [::]:80 default_server;

            root /var/www/public;
            index index.php index.html index.htm index.nginx-debian.html;

            server_name _;

            location = /favicon.ico { access_log off; log_not_found off; }
            location = /robots.txt  { access_log off; log_not_found off; }

            location / {
                try_files $uri $uri/ /index.php?$query_string;
            }

            location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.2-fpm.sock;
            }

            location ~ /\.ht {
                deny all;
            }
        }"
        echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

        sudo systemctl restart nginx

    fi
}
install_php










# /*===================================
# =            PHP MODULES            =
# ===================================*/
function install_phpmodules(){
    # Base Stuff
    sudo apt-get -y install php7.2-common
    sudo apt-get -y install php7.2-dev

    # Common Useful Stuff (some of these are probably already installed)
    sudo apt-get -y install php7.2-bcmath
    sudo apt-get -y install php7.2-bz2
    sudo apt-get -y install php7.2-cgi
    sudo apt-get -y install php7.2-cli
    sudo apt-get -y install php7.2-fpm
    sudo apt-get -y install php7.2-gd
    sudo apt-get -y install php7.2-imap
    sudo apt-get -y install php7.2-intl
    sudo apt-get -y install php7.2-json
    sudo apt-get -y install php7.2-mbstring
    sudo apt-get -y install php7.2-odbc
    sudo apt-get -y install php-pear
    sudo apt-get -y install php7.2-pspell
    sudo apt-get -y install php7.2-tidy
    sudo apt-get -y install php7.2-xmlrpc
    sudo apt-get -y install php7.2-zip

    # Enchant
    sudo apt-get -y install libenchant-dev
    sudo apt-get -y install php7.2-enchant

    # LDAP
    sudo apt-get -y install ldap-utils
    sudo apt-get -y install php7.2-ldap

    # CURL
    sudo apt-get -y install curl
    sudo apt-get -y install php7.2-curl

    # IMAGE MAGIC
    sudo apt-get -y install imagemagick
    sudo apt-get -y install php7.2-imagick
}
install_phpmodules





# /*===========================================
# =            CUSTOM PHP SETTINGS            =
# ===========================================*/

function php_settings(){
    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        PHP_USER_INI_PATH=/etc/php/7.2/fpm/conf.d/user.ini
    else
        PHP_USER_INI_PATH=/etc/php/7.2/apache2/conf.d/user.ini
    fi

    echo 'display_startup_errors = On' | sudo tee -a $PHP_USER_INI_PATH
    echo 'display_errors = On' | sudo tee -a $PHP_USER_INI_PATH
    echo 'error_reporting = E_ALL' | sudo tee -a $PHP_USER_INI_PATH
    echo 'short_open_tag = On' | sudo tee -a $PHP_USER_INI_PATH
    reboot_webserver_helper

    # Disable PHP Zend OPcache
    echo 'opache.enable = 0' | sudo tee -a $PHP_USER_INI_PATH

    # Absolutely Force Zend OPcache off...
    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.2/fpm/php.ini
    else
        sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.2/apache2/php.ini
    fi
    reboot_webserver_helper
}
php_settings







# /*================================
# =            PHP UNIT            =
# ================================*/
function install_phpunit(){
    sudo wget https://phar.phpunit.de/phpunit-6.1.phar
    sudo chmod +x phpunit-6.1.phar
    sudo mv phpunit-6.1.phar /usr/local/bin/phpunit
    reboot_webserver_helper
}
install_phpunit




# /*=============================
# =            MYSQL            =
# =============================*/
function install_mysql(){
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
    sudo apt-get -y install mysql-server
    sudo mysqladmin -uroot -proot create scotchbox
    sudo apt-get -y install php7.2-mysql
    reboot_webserver_helper
}
install_mysql




# /*=================================
# =            PostreSQL            =
# =================================*/
function install_postgresql(){
    sudo apt-get -y install postgresql postgresql-contrib
    echo "CREATE ROLE root WITH LOGIN ENCRYPTED PASSWORD 'root';" | sudo -i -u postgres psql
    sudo -i -u postgres createdb --owner=root scotchbox
    sudo apt-get -y install php7.2-pgsql
    reboot_webserver_helper
}
# install_postgresql




# /*==============================
# =            SQLITE            =
# ===============================*/
function install_sqlite(){
    sudo apt-get -y install sqlite
    sudo apt-get -y install php7.2-sqlite3
    reboot_webserver_helper
}
# install_sqlite




# /*===============================
# =            MONGODB            =
# ===============================*/
function install_mongodb(){
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sudo tee /lib/systemd/system/mongod.service  <<EOL
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable mongod
sudo service mongod start

# Enable it for PHP
sudo pecl install mongodb
sudo apt-get install -y php7.2-mongodb

reboot_webserver_helper
}
# install_mongodb



# /*================================
# =            COMPOSER            =
# ================================*/
function install_composer(){
    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
    
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
        >&2 alert_danger "ERROR: Invalid installer checksum"
        rm composer-setup.php
    fi
    
    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod 755 /usr/local/bin/composer
    alert_success "$RESULT"
}
install_composer








# /*==================================
# =            BEANSTALKD            =
# ==================================*/
function install_beanstalkd(){
    sudo apt-get -y install beanstalkd
}
# install_beanstalkd





# /*==============================
# =            WP-CLI            =
# ==============================*/
function install_wpcli(){
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sudo chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
}
# install_wpcli





# /*=============================
# =            NGROK            =
# =============================*/
function install_ngrok(){
    sudo apt-get install ngrok-client
}
# install_ngrok





# /*==============================
# =            NODEJS            =
# ==============================*/
function install_node(){
    sudo apt-get -y install nodejs
    sudo apt-get -y install npm

    # Use NVM though to make life easy
    wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | bash
    source ~/.nvm/nvm.sh
    nvm install 8.9.4

    # Node Packages
    sudo npm install -g gulp
    sudo npm install -g grunt
    sudo npm install -g bower
    sudo npm install -g yo
    sudo npm install -g browser-sync
    sudo npm install -g browserify
    sudo npm install -g pm2
    sudo npm install -g webpack
}
# install_node




# /*============================
# =            YARN            =
# ============================*/
function install_yarn(){
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get -y install yarn
}
# install_yarn





# /*============================
# =            RUBY            =
# ============================*/
function install_ruby(){
    sudo apt-get -y install ruby
    sudo apt-get -y install ruby-dev

    # Use RVM though to make life easy
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install 2.5.0
    rvm use 2.5.0
}
install_ruby




# /*=============================
# =            REDIS            =
# =============================*/
function install_redis(){
    sudo apt-get -y install redis-server
    sudo apt-get -y install php7.2-redis
    reboot_webserver_helper
}
# install_redis



# /*=================================
# =            MEMCACHED            =
# =================================*/
function install_memcached(){
    sudo apt-get -y install memcached
    sudo apt-get -y install php7.2-memcached
    reboot_webserver_helper
}
# install_memcached





# /*==============================
# =            GOLANG            =
# ==============================*/
function install_golang(){
    sudo add-apt-repository -y ppa:longsleep/golang-backports
    sudo apt-get update
    sudo apt-get -y install golang-go
}
# install_golang





# /*===============================
# =            MAILHOG            =
# ===============================*/
function install_mailhog(){
sudo wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
sudo chmod +x ~/mailhog

# Enable and Turn on
sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=MailHog Service
After=network.service vagrant.mount
[Service]
Type=simple
ExecStart=/usr/bin/env /home/vagrant/mailhog > /dev/null 2>&1 &
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable mailhog
sudo systemctl start mailhog

# Install Sendmail replacement for MailHog
sudo go get github.com/mailhog/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/sendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mail

# Make it work with PHP
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    echo 'sendmail_path = /usr/bin/mhsendmail' | sudo tee -a /etc/php/7.2/fpm/conf.d/user.ini
else
    echo 'sendmail_path = /usr/bin/mhsendmail' | sudo tee -a /etc/php/7.2/apache2/conf.d/user.ini
fi

reboot_webserver_helper
}
install_mailhog






# /*=======================================
# =            WELCOME MESSAGE            =
# =======================================*/

# Disable default messages by removing execute privilege
sudo chmod -x /etc/update-motd.d/*

# Set the new message
echo "$WELCOME_MESSAGE" | sudo tee /etc/motd



# /*===================================================
# =            FINAL GOOD MEASURE, WHY NOT            =
# ===================================================*/
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
reboot_webserver_helper



# /*====================================
# =            YOU ARE DONE            =
# ====================================*/
alert_success 'Lamp stack installed.'
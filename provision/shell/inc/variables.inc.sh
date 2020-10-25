#!/bin/bash
#
# variables.inc.sh
#

# @desc : This is the part you can edit
# ---------------------------------------
# Site_name must contain no space
INSTALL_NGINX_INSTEAD=0
STACK="apache"
WELCOME_MESSAGE=''
USE_HTTPS="1"

SITE_NAME="vm-starter"
PROJECT_DIR="public"
LOCALE="fr_FR"
TIMEZONE="Europe/Paris"
ADMIN_USER="admin"
ADMIN_PWD="azertiz67"
ADMIN_EMAIL="admin@gmail.com"
ADMIN_FIRSTNAME="admin"
ADMIN_LASTNAME="admin"

# Vagrant variables
# ---------------------------------------
DB_NAME="scotchbox"
DB_USER="root"
DB_PASS="root"
PHP_BASE_VERSION="7.2"
CMS="php without cms"
CMS_version="undefined"

# Filenames
# ---------------------------------------
FILE_APACHE="000-default"
FILE_APACHE_SSL="000-default-ssl"
FILE_APACHE_CONF="${FILE_APACHE}.conf"
FILE_APACHE_SSL_CONF="${FILE_APACHE_SSL}.conf"


# Paths
# ---------------------------------------
PATH_A2_SITES_AVAILABLE="/etc/apache2/sites-available/"
PATH_PUBLIC="/var/www/public/"
PATH_COMPOSER_JSON="${PATH_PUBLIC}/composer.json"
PATH_PROVISION="/var/www/provision/"
PATH_PROVISION_APACHE="${PATH_PROVISION}apache/"
PATH_PROVISION_SHELL="${PATH_PROVISION}shell/"
PATH_VAGRANT="/home/vagrant/"
WEB_ROOT="${PATH_PUBLIC}web"

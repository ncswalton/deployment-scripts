#!/bin/bash

########################################################
# Non-interactive install of apache2, php, and wordpress
# Configures WordPress for remote database
########################################################

apt-get install apache2 -y
apt-get install php libapache2-mod-php php-mysql -y

# edit apache2 config to make wordpress the active directory
sed -i '12s/$/\/wordpress/' /etc/apache2/sites-available/000-default.conf

# download & unzip wordpress
wget -P /var/www/html https://wordpress.org/latest.tar.gz
tar -xzvf /var/www/html/latest.tar.gz -C /var/www/html/

# change ownership of web directory to user running apache2
chown -R www-data:www-data /var/www/html/

# download wordpress secret keys & edit wordpress config file
wget -O /var/www/html/wordpress/wpdata.txt https://api.wordpress.org/secret-key/1.1/salt/
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
file=/var/www/html/wordpress/wp-config.php

sed -i '51,58d' $file
sed -i "51r /var/www/html/wordpress/wpdata.txt" $file
sed -i 's/database_name_here/wordpress_db/' $file
sed -i 's/username_here/wordpress_user/' $file
sed -i "s/password_here/$2/" $file
sed -i "s/localhost/$1/" $file

service apache2 restart
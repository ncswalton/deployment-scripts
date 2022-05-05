#!/bin/bash

#####################################################
# Non-interactive install of mysql-server
# Root and user passwords are passed in as arguments
#####################################################

export DEBIAN_FRONTEND=noninteractive
COUNTER=0

while ! apt-get -y --force-yes install mysql-server && [ $COUNTER -lt 10 ];
do
    apt-get \
    -o Dpkg::Options::=--force-confold \
    -o Dpkg::Options::=--force-confdef \
    -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    update

    apt-get \
    -o Dpkg::Options::=--force-confold \
    -o Dpkg::Options::=--force-confdef \
    -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    dist-upgrade

    let COUNTER=COUNTER+1
done

# preset responses for MySQL install prompts
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$2''
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$2''       

# create a new database 'wordpress_db'
mysql -uroot -p$2 -e "create database wordpress_db default character set utf8 collate utf8_unicode_ci;"
# create a user 'wordpress_user' associated with the webserver IP
mysql -uroot -p$2 -e "create user 'wordpress_user'@'$1' identified by '$3';"
# grant privs to wordpress_user@webserverIP
mysql -uroot -p$2 -e "grant all privileges on wordpress_db.* to 'wordpress_user'@'$1' with grant option;"
# edit config file to listen for remote connection
sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart